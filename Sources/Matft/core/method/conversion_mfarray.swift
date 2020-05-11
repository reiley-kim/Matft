//
//  conversion_mfarray.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation

extension MfArray{
    /**
       Create another typed mfarray. Created mfarray will be different object from original one
       - parameters:
            - mftype: the type of mfarray
    */
    public func astype(_ mftype: MfType) -> MfArray{
        return Matft.mfarray.astype(self, mftype: mftype)
    }
    /**
       Create any ordered transposed mfarray. Created mfarray will be sharing data with original one
       - parameters:
            - axes: (Optional) the indices of shape. In case this is left out, get transposed mfarray
    */
    public func transpose(axes: [Int]? = nil) -> MfArray{
        return Matft.mfarray.transpose(self, axes: axes)
    }
    /**
       Create transposed mfarray. Created mfarray will be sharing data with original one
       - parameters:
    */
    public var T: MfArray{
        return Matft.mfarray.transpose(self)
    }
    /**
       Convert new shaped mfarray
       - parameters:
            - newshape: the new shape
    */
    public func reshape(_ newshape: [Int]) -> MfArray{
        return Matft.mfarray.reshape(self, newshape: newshape)
    }
    /**
       Create broadcasted mfarray.
       - parameters:
            - shape: shape
       - throws:
        An error of type `MfError.conversionError`
    */
    public func broadcast_to(shape: [Int]) throws -> MfArray{
        return try Matft.mfarray.broadcast_to(self, shape: shape)
    }
    /**
       Create mfarray expanded dimension for given axis
       - parameters:
            - axis: the expanded axis
    */
    public static func expand_dims(axis: Int) -> MfArray{
        return Matft.mfarray.expand_dims(self, axis: axis)
    }
    /**
       Create mfarray expanded dimension for given axis
       - parameters:
            - axes: the list of expanded axes
    */
    public static func expand_dims(axes: [Int]) -> MfArray{
        return Matft.mfarray.expand_dims(self, axes: axes)
    }
    /**
       Create mfarray removed for 1-dimension
       - parameters:
            - axis: (Optional) the removed axis
    */
    public static func squeeze(axis: Int? = nil) -> MfArray{
        return Matft.mfarray.squeeze(self, axis: axis)
    }
    /**
       Create mfarray removed for 1-dimension
       - parameters:
            - mfarray: mfarray
            - axes: the list of  removed axes
    */
    public static func squeeze(axes: [Int]) -> MfArray{
        return Matft.mfarray.squeeze(self, axes: axes)
    }
    /**
       Convert order of stored data.
       - parameters:
            - mforder: mforder
    */
    public static func conv_order(mforder: MfOrder) -> MfArray{
        return Matft.mfarray.conv_order(self, mforder: mforder)
    }
    /**
       Flatten 1d-mfarray
       - parameters:
            - mforder: (Optional) mforder, default is Row
    */
    public static func flatten(mforder: MfOrder = .Row) -> MfArray{
        return Matft.mfarray.flatten(self, mforder: mforder)
    }
    /**
       Reverse the mfarray order along given axis
       - parameters:
            - axis: (optional) the reversed axis
    */
    public static func flip(axis: Int? = nil) -> MfArray{
        return Matft.mfarray.flip(self, axis: axis)
    }
    /**
       Reverse the mfarray order along given axes
       - parameters:
            - axes: (optional) the reversed axis of list
    */
    public static func flip(_ mfarray: MfArray, axes: [Int]? = nil) -> MfArray{
        return Matft.mfarray.flip(self, axes: axes)
    }
}
/*
extension MfData{
    /**
       Create another typed mfdata. Created mfdata will be different object from original one
       - parameters:
            - mftype: the type of mfarray
    */
    public func astype(_ mftype: MfType) -> MfData{
        return Matft.mfarray.mfdata.astype(self, mftype: mftype)
    }
}
*/
