//
//  vDSP.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/27.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

//converter
internal typealias vDSP_convert_func<T, U> = (UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<U>, vDSP_Stride, vDSP_Length) -> Void

internal func unsafePtrT2UnsafeMPtrU<T: MfTypable, U: MfTypable>(_ srcptr: UnsafePointer<T>,  _ dstptr: UnsafeMutablePointer<U>, _ vDSP_func: vDSP_convert_func<T, U>, _ count: Int){
    vDSP_func(srcptr, vDSP_Stride(1), dstptr, vDSP_Stride(1), vDSP_Length(count))
}
internal func preop_by_vDSP<T: MfStorable>(_ mfarray: MfArray, _ vDSP_func: vDSP_convert_func<T, T>) -> MfArray{
    
    let newdata = withDummyDataMRPtr(mfarray.mftype, storedSize: mfarray.storedSize){
        dstptr in
        let dstptrT = dstptr.bindMemory(to: T.self, capacity: mfarray.storedSize)
        mfarray.withDataUnsafeMBPtrT(datatype: T.self){
            vDSP_func($0.baseAddress!, vDSP_Stride(1), dstptrT, vDSP_Stride(1), vDSP_Length(mfarray.storedSize))
        }
    }
    
    let newmfstructure = copy_mfstructure(mfarray.mfstructure)
    return MfArray(mfdata: newdata, mfstructure: newmfstructure)
}

//binary operation
internal typealias vDSP_biop_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Stride, vDSP_Length) -> Void

internal func biop_unsafePtrT<T: MfStorable>(lptr: UnsafePointer<T>, _ lstride: Int, rptr: UnsafePointer<T>, _ rstride: Int, dstptr: UnsafeMutablePointer<T>, _ dststride: Int, _ blockSize: Int, _ vDSP_func: vDSP_biop_func<T>){
    vDSP_func(rptr, vDSP_Stride(rstride), lptr, vDSP_Stride(lstride), dstptr, vDSP_Stride(dststride), vDSP_Length(blockSize))
}

internal func biop_by_vDSP<T: MfStorable>(_ l_mfarray: MfArray, _ r_mfarray: MfArray, vDSP_func: vDSP_biop_func<T>) -> MfArray{
    var biggerL: Bool // flag whether l is bigger than r
    var l_mfarray = l_mfarray
    //return mfarray must be either row or column major
    if r_mfarray.mfflags.column_contiguous || r_mfarray.mfflags.row_contiguous{
        biggerL = false
    }
    else if l_mfarray.mfflags.column_contiguous || l_mfarray.mfflags.row_contiguous{
        biggerL = true
    }
    else{
        l_mfarray = Matft.mfarray.conv_order(l_mfarray, mforder: .Row)
        biggerL = true
    }
    
    
    let newdata = withDummyDataMRPtr(l_mfarray.mftype, storedSize: l_mfarray.storedSize){
        dstptr in
        let dstptrT = dstptr.bindMemory(to: T.self, capacity: l_mfarray.storedSize)
        
        l_mfarray.withDataUnsafeMBPtrT(datatype: T.self){
            lptr in
            r_mfarray.withDataUnsafeMBPtrT(datatype: T.self){
                rptr in
                //print(l_mfarray, r_mfarray)
                //print(l_mfarray.storedSize, r_mfarray.storedSize)
                if biggerL{// l is bigger
                    for vDSPPrams in OptOffsetParams(bigger_mfarray: l_mfarray, smaller_mfarray: r_mfarray){
                        /*
                        let bptr = bptr.baseAddress! + vDSPPrams.b_offset
                        let sptr = sptr.baseAddress! + vDSPPrams.s_offset
                        dstptrT = dstptrT + vDSPPrams.b_offset*/
                        biop_unsafePtrT(lptr: lptr.baseAddress! + vDSPPrams.b_offset, vDSPPrams.b_stride, rptr: rptr.baseAddress! + vDSPPrams.s_offset, vDSPPrams.s_stride, dstptr: dstptrT + vDSPPrams.b_offset, vDSPPrams.b_stride, vDSPPrams.blocksize, vDSP_func)
                        //print(vDSPPrams.b_offset,vDSPPrams.b_stride,vDSPPrams.s_offset, vDSPPrams.s_stride)
                    }
                }
                else{// r is bigger
                    for vDSPPrams in OptOffsetParams(bigger_mfarray: r_mfarray, smaller_mfarray: l_mfarray){
                        biop_unsafePtrT(lptr: lptr.baseAddress! + vDSPPrams.s_offset, vDSPPrams.s_stride, rptr: rptr.baseAddress! + vDSPPrams.b_offset, vDSPPrams.b_stride, dstptr: dstptrT + vDSPPrams.b_offset, vDSPPrams.b_stride, vDSPPrams.blocksize, vDSP_func)
                        //print(vDSPPrams.b_offset,vDSPPrams.b_stride,vDSPPrams.s_offset, vDSPPrams.s_stride)
                    }
                }
            }
        }
    }
    
    let newmfstructure = copy_mfstructure(biggerL ? l_mfarray.mfstructure : r_mfarray.mfstructure)
    return MfArray(mfdata: newdata, mfstructure: newmfstructure)
}

//get stats for mfarray
internal typealias vDSP_stats_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, vDSP_Length) -> Void
fileprivate func _stats_run<T: MfStorable>(_ srcptr: UnsafePointer<T>, _ dstptr: UnsafeMutablePointer<T>, vDSP_func: vDSP_stats_func<T>, stride: Int, _ count: Int){
    
    vDSP_func(srcptr, vDSP_Stride(stride), dstptr, vDSP_Length(count))
}

// for along given axis
internal func stats_axis_by_vDSP<T: MfStorable>(_ mfarray: MfArray, axis: Int, vDSP_func: vDSP_stats_func<T>) -> MfArray{
    var retShape = mfarray.shape
    let count = retShape.remove(at: axis)
    var retStrides = mfarray.strides
    //remove and get stride at given axis
    let stride = retStrides.remove(at: axis)
    
    
    let retndim = retShape.count

    let ret = withDummy(mftype: mfarray.mftype, storedSize: mfarray.storedSize, ndim: retndim){
        dataptr, shapeptr, stridesptr in

        //move
        shapeptr.baseAddress!.moveAssign(from: &retShape, count: retndim)
        
        //move
        stridesptr.baseAddress!.moveAssign(from: &retStrides, count: retndim)
        
        
        mfarray.withDataUnsafeMBPtrT(datatype: T.self){
            srcptr in
            var dstptr = dataptr.bindMemory(to: T.self, capacity: shape2size(shapeptr))
            for flat in FlattenIndSequence(shapeptr: shapeptr, stridesptr: stridesptr){
                _stats_run(srcptr.baseAddress! + flat.flattenIndex, dstptr, vDSP_func: vDSP_func, stride: stride, count)
                dstptr += 1
                //print(flat.flattenIndex, flat.indices)
            }
        }
        
        //row major order because FlattenIndSequence count up for row major
        let newstridesptr = shape2strides(shapeptr, mforder: .Row)
        //move
        stridesptr.baseAddress!.moveAssign(from: newstridesptr.baseAddress!, count: retndim)
        //free
        newstridesptr.deallocate()
    }

    return ret
}

// for all elements
internal func stats_all_by_vDSP<T: MfStorable>(_ mfarray: MfArray, vDSP_func: vDSP_stats_func<T>) -> MfArray{
    var dst = T.zero
    mfarray.withDataUnsafeMBPtrT(datatype: T.self){
        _stats_run($0.baseAddress!, &dst, vDSP_func: vDSP_func, stride: 1, mfarray.size)
    }
    
    return MfArray([dst], mftype: mfarray.mftype)
}


internal typealias vDSP_stats_index_func<T> = (UnsafePointer<T>, vDSP_Stride, UnsafeMutablePointer<T>, UnsafeMutablePointer<vDSP_Length>, vDSP_Length) -> Void

fileprivate func _stats_index_run<T: MfStorable>(_ srcptr: UnsafePointer<T>, vDSP_func: vDSP_stats_index_func<T>, stride: Int32, _ count: Int) -> Int32{
    var ret = vDSP_Length(0)
    var tmpdst = T.zero
    vDSP_func(srcptr, vDSP_Stride(stride), &tmpdst, &ret, vDSP_Length(count))

    return Int32(ret)
}

//for along given axis
internal func stats_index_axis_by_vDSP<T: MfStorable>(_ mfarray: MfArray, axis: Int, vDSP_func: vDSP_stats_index_func<T>, vDSP_conv_func: vDSP_convert_func<Int32, T>) -> MfArray{
    var retShape = mfarray.shape
    let count = retShape.remove(at: axis)
    var retStrides = mfarray.strides
    //remove and get stride at given axis
    let stride = Int32(retStrides.remove(at: axis))
    
    
    let retndim = retShape.count

    let ret = withDummy(mftype: MfType.Int, storedSize: mfarray.storedSize, ndim: retndim){
        dataptr, shapeptr, stridesptr in

        //move
        shapeptr.baseAddress!.moveAssign(from: &retShape, count: retndim)
        
        //move
        stridesptr.baseAddress!.moveAssign(from: &retStrides, count: retndim)
        
        let retsize = shape2size(shapeptr)
        mfarray.withDataUnsafeMBPtrT(datatype: T.self){
            srcptr in

            var i32array = Array<Int32>(repeating: 0, count: retsize)
            //let srcptr = stride >= 0 ? srcptr.baseAddress! : srcptr.baseAddress! - mfarray.offsetIndex
            let srcptr = srcptr.baseAddress!
            for (i, flat) in FlattenIndSequence(shapeptr: shapeptr, stridesptr: stridesptr).enumerated(){
                i32array[i] = _stats_index_run(srcptr + flat.flattenIndex, vDSP_func: vDSP_func, stride: stride, count) / stride
                //print(flat.flattenIndex, flat.indices)
            }
            
            let dstptr = dataptr.bindMemory(to: T.self, capacity: retsize)
            //convert dataptr(int) to float
            i32array.withUnsafeBufferPointer{
                unsafePtrT2UnsafeMPtrU($0.baseAddress!, dstptr, vDSP_conv_func, retsize)
            }
            
        }
        
        
        //row major order because FlattenIndSequence count up for row major
        let newstridesptr = shape2strides(shapeptr, mforder: .Row)
        //move
        stridesptr.baseAddress!.moveAssign(from: newstridesptr.baseAddress!, count: retndim)
        //free
        newstridesptr.deallocate()
    }

    return ret
}

// for all elements
internal func stats_index_all_by_vDSP<T: MfStorable>(_ mfarray: MfArray, vDSP_func: vDSP_stats_index_func<T>) -> MfArray{

    let dst = mfarray.withDataUnsafeMBPtrT(datatype: T.self){
        Int(_stats_index_run($0.baseAddress!, vDSP_func: vDSP_func, stride: 1, mfarray.size))
    }
    
    return MfArray([dst])
}


