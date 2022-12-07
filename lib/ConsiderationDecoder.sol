// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {
    BasicOrderParameters,
    Order,
    CriteriaResolver,
    AdvancedOrder,
    FulfillmentComponent,
    Execution,
    Fulfillment,
    OrderComponents,
    OrderParameters
} from "./ConsiderationStructs.sol";
import "./PointerLibraries.sol";

contract ConsiderationDecoder {
    uint256 constant BasicOrderParameters_head_size = 0x0240;
    uint256 constant BasicOrderParameters_fixed_segment_0 = 0x0200;
    uint256 constant BasicOrderParameters_additionalRecipients_offset = 0x0200;
    uint256 constant BasicOrderParameters_signature_offset = 0x0220;

    uint256 constant AdditionalRecipient_mem_tail_size = 0x40;

    uint256 constant AlmostTwoWords = 0x3f;
    uint256 constant OnlyFullWordMask = 0xffffe0;

    uint256 constant OrderParameters_head_size = 0x0160;
    uint256 constant OrderParameters_offer_offset = 0x40;
    uint256 constant OrderParameters_consideration_offset = 0x60;
    uint256 constant OrderParameters_totalOriginalConsiderationItems_offset = (
        0x0140
    );

    uint256 constant OfferItem_mem_tail_size = 0xa0;

    uint256 constant ConsiderationItem_mem_tail_size = 0xc0;

    uint256 constant Order_signature_offset = 0x20;
    uint256 constant Order_head_size = 0x40;

    uint256 constant AdvancedOrder_head_size = 0xa0;
    uint256 constant AdvancedOrder_fixed_segment_0 = 0x40;
    uint256 constant AdvancedOrder_numerator_offset = 0x20;
    uint256 constant AdvancedOrder_denominator_offset = 0x40;
    uint256 constant AdvancedOrder_signature_offset = 0x60;
    uint256 constant AdvancedOrder_extraData_offset = 0x80;

    uint256 constant CriteriaResolver_head_size = 0xa0;
    uint256 constant CriteriaResolver_fixed_segment_0 = 0x80;
    uint256 constant CriteriaResolver_criteriaProof_offset = 0x80;

    uint256 constant FulfillmentComponent_mem_tail_size = 0x40;
    uint256 constant Fulfillment_head_size = 0x40;
    uint256 constant Fulfillment_considerationComponents_offset = 0x20;

    uint256 constant OrderComponents_head_size = 0x0160;
    uint256 constant OrderComponents_offer_offset = 0x40;
    uint256 constant OrderComponents_consideration_offset = 0x60;
    uint256 constant OrderComponents_OrderParameters_common_head_size = 0x0140;
    uint256 constant OrderParameters_counter_offset = 0x0140;

    function abi_decode_dyn_array_AdditionalRecipient(
        CalldataPointer cdPtrLength
    ) internal pure returns (MemoryPointer mPtrLength) {
        assembly {
            let arrLength := and(calldataload(cdPtrLength), OffsetOrLengthMask)
            mPtrLength := mload(0x40)
            mstore(mPtrLength, arrLength)
            let mPtrHead := add(mPtrLength, 32)
            let mPtrTail := add(mPtrHead, mul(arrLength, 0x20))
            let mPtrTailNext := mPtrTail
            calldatacopy(
                mPtrTail,
                add(cdPtrLength, 0x20),
                mul(arrLength, AdditionalRecipient_mem_tail_size)
            )
            let mPtrHeadNext := mPtrHead
            for {

            } lt(mPtrHeadNext, mPtrTail) {

            } {
                mstore(mPtrHeadNext, mPtrTailNext)
                mPtrHeadNext := add(mPtrHeadNext, 0x20)
                mPtrTailNext := add(
                    mPtrTailNext,
                    AdditionalRecipient_mem_tail_size
                )
            }
            mstore(0x40, mPtrTailNext)
        }
    }

    function abi_decode_bytes(
        CalldataPointer cdPtrLength
    ) internal pure returns (MemoryPointer mPtrLength) {
        assembly {
            mPtrLength := mload(0x40)
            let size := and(
                add(
                    and(calldataload(cdPtrLength), OffsetOrLengthMask),
                    AlmostTwoWords
                ),
                OnlyFullWordMask
            )
            calldatacopy(mPtrLength, cdPtrLength, size)
            mstore(0x40, add(mPtrLength, size))
        }
    }

    function abi_decode_BasicOrderParameters(
        CalldataPointer cdPtr
    ) internal pure returns (MemoryPointer mPtr) {
        mPtr = malloc(BasicOrderParameters_head_size);
        cdPtr.copy(mPtr, BasicOrderParameters_fixed_segment_0);
        mPtr.offset(BasicOrderParameters_additionalRecipients_offset).write(
            abi_decode_dyn_array_AdditionalRecipient(
                cdPtr.pptr(BasicOrderParameters_additionalRecipients_offset)
            )
        );
        mPtr.offset(BasicOrderParameters_signature_offset).write(
            abi_decode_bytes(cdPtr.pptr(BasicOrderParameters_signature_offset))
        );
    }

    function abi_decode_dyn_array_OfferItem(
        CalldataPointer cdPtrLength
    ) internal pure returns (MemoryPointer mPtrLength) {
        assembly {
            let arrLength := and(calldataload(cdPtrLength), OffsetOrLengthMask)
            mPtrLength := mload(0x40)
            mstore(mPtrLength, arrLength)
            let mPtrHead := add(mPtrLength, 32)
            let mPtrTail := add(mPtrHead, mul(arrLength, 0x20))
            let mPtrTailNext := mPtrTail
            calldatacopy(
                mPtrTail,
                add(cdPtrLength, 0x20),
                mul(arrLength, OfferItem_mem_tail_size)
            )
            let mPtrHeadNext := mPtrHead
            for {

            } lt(mPtrHeadNext, mPtrTail) {

            } {
                mstore(mPtrHeadNext, mPtrTailNext)
                mPtrHeadNext := add(mPtrHeadNext, 0x20)
                mPtrTailNext := add(mPtrTailNext, OfferItem_mem_tail_size)
            }
            mstore(0x40, mPtrTailNext)
        }
    }

    function abi_decode_dyn_array_ConsiderationItem(
        CalldataPointer cdPtrLength
    ) internal pure returns (MemoryPointer mPtrLength) {
        assembly {
            let arrLength := and(calldataload(cdPtrLength), OffsetOrLengthMask)
            mPtrLength := mload(0x40)
            mstore(mPtrLength, arrLength)
            let mPtrHead := add(mPtrLength, 32)
            let mPtrTail := add(mPtrHead, mul(arrLength, 0x20))
            let mPtrTailNext := mPtrTail
            calldatacopy(
                mPtrTail,
                add(cdPtrLength, 0x20),
                mul(arrLength, ConsiderationItem_mem_tail_size)
            )
            let mPtrHeadNext := mPtrHead
            for {

            } lt(mPtrHeadNext, mPtrTail) {

            } {
                mstore(mPtrHeadNext, mPtrTailNext)
                mPtrHeadNext := add(mPtrHeadNext, 0x20)
                mPtrTailNext := add(
                    mPtrTailNext,
                    ConsiderationItem_mem_tail_size
                )
            }
            mstore(0x40, mPtrTailNext)
        }
    }

    function abi_decode_OrderParameters_to(
        CalldataPointer cdPtr,
        MemoryPointer mPtr
    ) internal pure {
        cdPtr.copy(mPtr, OrderParameters_head_size);
        mPtr.offset(OrderParameters_offer_offset).write(
            abi_decode_dyn_array_OfferItem(
                cdPtr.pptr(OrderParameters_offer_offset)
            )
        );
        mPtr.offset(OrderParameters_consideration_offset).write(
            abi_decode_dyn_array_ConsiderationItem(
                cdPtr.pptr(OrderParameters_consideration_offset)
            )
        );
    }

    function abi_decode_OrderParameters(
        CalldataPointer cdPtr
    ) internal pure returns (MemoryPointer mPtr) {
        mPtr = malloc(OrderParameters_head_size);
        abi_decode_OrderParameters_to(cdPtr, mPtr);
    }

    function abi_decode_Order(
        CalldataPointer cdPtr
    ) internal pure returns (MemoryPointer mPtr) {
        mPtr = malloc(Order_head_size);
        mPtr.write(abi_decode_OrderParameters(cdPtr.pptr()));
        mPtr.offset(Order_signature_offset).write(
            abi_decode_bytes(cdPtr.pptr(Order_signature_offset))
        );
    }

    function abi_decode_AdvancedOrder(
        CalldataPointer cdPtr
    ) internal pure returns (MemoryPointer mPtr) {
        // Allocate memory for AdvancedOrder head and OrderParameters head
        mPtr = malloc(AdvancedOrder_head_size + OrderParameters_head_size);

        // Copy order numerator and denominator
        cdPtr.offset(AdvancedOrder_numerator_offset).copy(
            mPtr.offset(AdvancedOrder_numerator_offset),
            AdvancedOrder_fixed_segment_0
        );

        // Get pointer to memory immediately after advanced order
        MemoryPointer mPtrParameters = mPtr.offset(AdvancedOrder_head_size);
        // Write pptr for advanced order parameters
        mPtr.write(mPtrParameters);
        // Copy order parameters to allocated region
        abi_decode_OrderParameters_to(cdPtr.pptr(), mPtrParameters);

        // mPtr.write(abi_decode_OrderParameters(cdPtr.pptr()));
        mPtr.offset(AdvancedOrder_signature_offset).write(
            abi_decode_bytes(cdPtr.pptr(AdvancedOrder_signature_offset))
        );
        mPtr.offset(AdvancedOrder_extraData_offset).write(
            abi_decode_bytes(cdPtr.pptr(AdvancedOrder_extraData_offset))
        );
    }

    function getEmptyBytesOrArray() internal pure returns (MemoryPointer mPtr) {
        mPtr = malloc(32);
        mPtr.write(0);
    }

    function abi_decode_Order_as_AdvancedOrder(
        CalldataPointer cdPtr
    ) internal pure returns (MemoryPointer mPtr) {
        // Allocate memory for AdvancedOrder head and OrderParameters head
        mPtr = malloc(AdvancedOrder_head_size + OrderParameters_head_size);

        // Get pointer to memory immediately after advanced order
        MemoryPointer mPtrParameters = mPtr.offset(AdvancedOrder_head_size);
        // Write pptr for advanced order parameters
        mPtr.write(mPtrParameters);
        // Copy order parameters to allocated region
        abi_decode_OrderParameters_to(cdPtr.pptr(), mPtrParameters);

        mPtr.offset(AdvancedOrder_numerator_offset).write(1);
        mPtr.offset(AdvancedOrder_denominator_offset).write(1);

        // Copy order signature to advanced order signature
        mPtr.offset(AdvancedOrder_signature_offset).write(
            abi_decode_bytes(cdPtr.pptr(Order_signature_offset))
        );

        // Set empty bytes for advanced order extraData
        mPtr.offset(AdvancedOrder_extraData_offset).write(
            getEmptyBytesOrArray()
        );
    }

    function abi_decode_dyn_array_Order_as_dyn_array_AdvancedOrder(
        CalldataPointer cdPtrLength
    ) internal pure returns (MemoryPointer mPtrLength) {
        unchecked {
            uint256 arrLength = cdPtrLength.readMaskedUint256();
            uint256 tailOffset = arrLength * 32;
            mPtrLength = malloc(tailOffset + 32);
            mPtrLength.write(arrLength);
            MemoryPointer mPtrHead = mPtrLength.next();
            CalldataPointer cdPtrHead = cdPtrLength.next();
            for (uint256 offset; offset < tailOffset; offset += 32) {
                mPtrHead.offset(offset).write(
                    abi_decode_Order_as_AdvancedOrder(cdPtrHead.pptr(offset))
                );
            }
        }
    }

    function abi_decode_dyn_array_bytes32(
        CalldataPointer cdPtrLength
    ) internal pure returns (MemoryPointer mPtrLength) {
        unchecked {
            uint256 arrLength = cdPtrLength.readMaskedUint256();
            uint256 arrSize = (arrLength + 1) * 32;
            mPtrLength = malloc(arrSize);
            cdPtrLength.copy(mPtrLength, arrSize);
        }
    }

    function abi_decode_CriteriaResolver(
        CalldataPointer cdPtr
    ) internal pure returns (MemoryPointer mPtr) {
        mPtr = malloc(CriteriaResolver_head_size);
        cdPtr.copy(mPtr, CriteriaResolver_fixed_segment_0);
        mPtr.offset(CriteriaResolver_criteriaProof_offset).write(
            abi_decode_dyn_array_bytes32(
                cdPtr.pptr(CriteriaResolver_criteriaProof_offset)
            )
        );
    }

    function abi_decode_dyn_array_CriteriaResolver(
        CalldataPointer cdPtrLength
    ) internal pure returns (MemoryPointer mPtrLength) {
        unchecked {
            uint256 arrLength = cdPtrLength.readMaskedUint256();
            uint256 tailOffset = arrLength * 32;
            mPtrLength = malloc(tailOffset + 32);
            mPtrLength.write(arrLength);
            MemoryPointer mPtrHead = mPtrLength.next();
            CalldataPointer cdPtrHead = cdPtrLength.next();
            for (uint256 offset; offset < tailOffset; offset += 32) {
                mPtrHead.offset(offset).write(
                    abi_decode_CriteriaResolver(cdPtrHead.pptr(offset))
                );
            }
        }
    }

    function abi_decode_dyn_array_Order(
        CalldataPointer cdPtrLength
    ) internal pure returns (MemoryPointer mPtrLength) {
        unchecked {
            uint256 arrLength = cdPtrLength.readMaskedUint256();
            uint256 tailOffset = arrLength * 32;
            mPtrLength = malloc(tailOffset + 32);
            mPtrLength.write(arrLength);
            MemoryPointer mPtrHead = mPtrLength.next();
            CalldataPointer cdPtrHead = cdPtrLength.next();
            for (uint256 offset; offset < tailOffset; offset += 32) {
                mPtrHead.offset(offset).write(
                    abi_decode_Order(cdPtrHead.pptr(offset))
                );
            }
        }
    }

    function abi_decode_dyn_array_FulfillmentComponent(
        CalldataPointer cdPtrLength
    ) internal pure returns (MemoryPointer mPtrLength) {
        assembly {
            let arrLength := and(calldataload(cdPtrLength), OffsetOrLengthMask)
            mPtrLength := mload(0x40)
            mstore(mPtrLength, arrLength)
            let mPtrHead := add(mPtrLength, 32)
            let mPtrTail := add(mPtrHead, mul(arrLength, 0x20))
            let mPtrTailNext := mPtrTail
            calldatacopy(
                mPtrTail,
                add(cdPtrLength, 0x20),
                mul(arrLength, FulfillmentComponent_mem_tail_size)
            )
            let mPtrHeadNext := mPtrHead
            for {

            } lt(mPtrHeadNext, mPtrTail) {

            } {
                mstore(mPtrHeadNext, mPtrTailNext)
                mPtrHeadNext := add(mPtrHeadNext, 0x20)
                mPtrTailNext := add(
                    mPtrTailNext,
                    FulfillmentComponent_mem_tail_size
                )
            }
            mstore(0x40, mPtrTailNext)
        }
    }

    function abi_decode_dyn_array_dyn_array_FulfillmentComponent(
        CalldataPointer cdPtrLength
    ) internal pure returns (MemoryPointer mPtrLength) {
        unchecked {
            uint256 arrLength = cdPtrLength.readMaskedUint256();
            uint256 tailOffset = arrLength * 32;
            mPtrLength = malloc(tailOffset + 32);
            mPtrLength.write(arrLength);
            MemoryPointer mPtrHead = mPtrLength.next();
            CalldataPointer cdPtrHead = cdPtrLength.next();
            for (uint256 offset; offset < tailOffset; offset += 32) {
                mPtrHead.offset(offset).write(
                    abi_decode_dyn_array_FulfillmentComponent(
                        cdPtrHead.pptr(offset)
                    )
                );
            }
        }
    }

    function abi_decode_dyn_array_AdvancedOrder(
        CalldataPointer cdPtrLength
    ) internal pure returns (MemoryPointer mPtrLength) {
        unchecked {
            uint256 arrLength = cdPtrLength.readMaskedUint256();
            uint256 tailOffset = arrLength * 32;
            mPtrLength = malloc(tailOffset + 32);
            mPtrLength.write(arrLength);
            MemoryPointer mPtrHead = mPtrLength.next();
            CalldataPointer cdPtrHead = cdPtrLength.next();
            for (uint256 offset; offset < tailOffset; offset += 32) {
                mPtrHead.offset(offset).write(
                    abi_decode_AdvancedOrder(cdPtrHead.pptr(offset))
                );
            }
        }
    }

    function abi_decode_Fulfillment(
        CalldataPointer cdPtr
    ) internal pure returns (MemoryPointer mPtr) {
        mPtr = malloc(Fulfillment_head_size);
        mPtr.write(abi_decode_dyn_array_FulfillmentComponent(cdPtr.pptr()));
        mPtr.offset(Fulfillment_considerationComponents_offset).write(
            abi_decode_dyn_array_FulfillmentComponent(
                cdPtr.pptr(Fulfillment_considerationComponents_offset)
            )
        );
    }

    function abi_decode_dyn_array_Fulfillment(
        CalldataPointer cdPtrLength
    ) internal pure returns (MemoryPointer mPtrLength) {
        unchecked {
            uint256 arrLength = cdPtrLength.readMaskedUint256();
            uint256 tailOffset = arrLength * 32;
            mPtrLength = malloc(tailOffset + 32);
            mPtrLength.write(arrLength);
            MemoryPointer mPtrHead = mPtrLength.next();
            CalldataPointer cdPtrHead = cdPtrLength.next();
            for (uint256 offset; offset < tailOffset; offset += 32) {
                mPtrHead.offset(offset).write(
                    abi_decode_Fulfillment(cdPtrHead.pptr(offset))
                );
            }
        }
    }

    function abi_decode_OrderComponents(
        CalldataPointer cdPtr
    ) internal pure returns (MemoryPointer mPtr) {
        mPtr = malloc(OrderComponents_head_size);
        cdPtr.copy(mPtr, OrderComponents_head_size);
        mPtr.offset(OrderComponents_offer_offset).write(
            abi_decode_dyn_array_OfferItem(
                cdPtr.pptr(OrderComponents_offer_offset)
            )
        );
        mPtr.offset(OrderComponents_consideration_offset).write(
            abi_decode_dyn_array_ConsiderationItem(
                cdPtr.pptr(OrderComponents_consideration_offset)
            )
        );
    }

    function abi_decode_dyn_array_OrderComponents(
        CalldataPointer cdPtrLength
    ) internal pure returns (MemoryPointer mPtrLength) {
        unchecked {
            uint256 arrLength = cdPtrLength.readMaskedUint256();
            uint256 tailOffset = arrLength * 32;
            mPtrLength = malloc(tailOffset + 32);
            mPtrLength.write(arrLength);
            MemoryPointer mPtrHead = mPtrLength.next();
            CalldataPointer cdPtrHead = cdPtrLength.next();
            for (uint256 offset; offset < tailOffset; offset += 32) {
                mPtrHead.offset(offset).write(
                    abi_decode_OrderComponents(cdPtrHead.pptr(offset))
                );
            }
        }
    }

    function abi_decode_OrderComponents_as_OrderParameters(
        CalldataPointer cdPtr
    ) internal pure returns (MemoryPointer mPtr) {
        mPtr = malloc(OrderParameters_head_size);
        cdPtr.copy(mPtr, OrderComponents_OrderParameters_common_head_size);
        mPtr.offset(OrderParameters_offer_offset).write(
            abi_decode_dyn_array_OfferItem(
                cdPtr.pptr(OrderParameters_offer_offset)
            )
        );
        MemoryPointer consideration = abi_decode_dyn_array_ConsiderationItem(
            cdPtr.pptr(OrderParameters_consideration_offset)
        );
        mPtr.offset(OrderParameters_consideration_offset).write(consideration);
        // Write totalOriginalConsiderationItems
        mPtr
            .offset(OrderParameters_totalOriginalConsiderationItems_offset)
            .write(consideration.read());
    }

    function to_BasicOrderParameters_ReturnType(
        function(CalldataPointer) internal pure returns (MemoryPointer) inFn
    )
        internal
        pure
        returns (
            function(CalldataPointer)
                internal
                pure
                returns (BasicOrderParameters memory) outFn
        )
    {
        assembly {
            outFn := inFn
        }
    }

    function to_Order_ReturnType(
        function(CalldataPointer) internal pure returns (MemoryPointer) inFn
    )
        internal
        pure
        returns (
            function(CalldataPointer) internal pure returns (Order memory) outFn
        )
    {
        assembly {
            outFn := inFn
        }
    }

    function to_OrderParameters_ReturnType(
        function(CalldataPointer) internal pure returns (MemoryPointer) inFn
    )
        internal
        pure
        returns (
            function(CalldataPointer)
                internal
                pure
                returns (OrderParameters memory) outFn
        )
    {
        assembly {
            outFn := inFn
        }
    }

    function to_AdvancedOrder_ReturnType(
        function(CalldataPointer) internal pure returns (MemoryPointer) inFn
    )
        internal
        pure
        returns (
            function(CalldataPointer)
                internal
                pure
                returns (AdvancedOrder memory) outFn
        )
    {
        assembly {
            outFn := inFn
        }
    }

    function to_dyn_array_CriteriaResolver_ReturnType(
        function(CalldataPointer) internal pure returns (MemoryPointer) inFn
    )
        internal
        pure
        returns (
            function(CalldataPointer)
                internal
                pure
                returns (CriteriaResolver[] memory) outFn
        )
    {
        assembly {
            outFn := inFn
        }
    }

    function to_dyn_array_Order_ReturnType(
        function(CalldataPointer) internal pure returns (MemoryPointer) inFn
    )
        internal
        pure
        returns (
            function(CalldataPointer)
                internal
                pure
                returns (Order[] memory) outFn
        )
    {
        assembly {
            outFn := inFn
        }
    }

    function to_dyn_array_dyn_array_FulfillmentComponent_ReturnType(
        function(CalldataPointer) internal pure returns (MemoryPointer) inFn
    )
        internal
        pure
        returns (
            function(CalldataPointer)
                internal
                pure
                returns (FulfillmentComponent[][] memory) outFn
        )
    {
        assembly {
            outFn := inFn
        }
    }

    function to_dyn_array_AdvancedOrder_ReturnType(
        function(CalldataPointer) internal pure returns (MemoryPointer) inFn
    )
        internal
        pure
        returns (
            function(CalldataPointer)
                internal
                pure
                returns (AdvancedOrder[] memory) outFn
        )
    {
        assembly {
            outFn := inFn
        }
    }

    function to_dyn_array_Fulfillment_ReturnType(
        function(CalldataPointer) internal pure returns (MemoryPointer) inFn
    )
        internal
        pure
        returns (
            function(CalldataPointer)
                internal
                pure
                returns (Fulfillment[] memory) outFn
        )
    {
        assembly {
            outFn := inFn
        }
    }

    function to_dyn_array_OrderComponents_ReturnType(
        function(CalldataPointer) internal pure returns (MemoryPointer) inFn
    )
        internal
        pure
        returns (
            function(CalldataPointer)
                internal
                pure
                returns (OrderComponents[] memory) outFn
        )
    {
        assembly {
            outFn := inFn
        }
    }

    function to_OrderComponents_ReturnType(
        function(CalldataPointer) internal pure returns (MemoryPointer) inFn
    )
        internal
        pure
        returns (
            function(CalldataPointer)
                internal
                pure
                returns (OrderComponents memory) outFn
        )
    {
        assembly {
            outFn := inFn
        }
    }

    function return_bool(bool fulfilled) internal pure {
        bytes memory returnData = abi.encode(fulfilled);
        assembly {
            return(add(returnData, 32), mload(returnData))
        }
    }

    function return_uint256(uint256 newCounter) internal pure {
        bytes memory returnData = abi.encode(newCounter);
        assembly {
            return(add(returnData, 32), mload(returnData))
        }
    }

    function return_bytes32(bytes32 orderHash) internal pure {
        bytes memory returnData = abi.encode(orderHash);
        assembly {
            return(add(returnData, 32), mload(returnData))
        }
    }

    function return_tuple_bool_bool_uint256_uint256(
        bool isValidated,
        bool isCancelled,
        uint256 totalFilled,
        uint256 totalSize
    ) internal pure {
        bytes memory returnData = abi.encode(
            isValidated,
            isCancelled,
            totalFilled,
            totalSize
        );
        assembly {
            return(add(returnData, 32), mload(returnData))
        }
    }

    function return_tuple_string_bytes32_address(
        string memory version,
        bytes32 domainSeparator,
        address conduitController
    ) internal pure {
        bytes memory returnData = abi.encode(
            version,
            domainSeparator,
            conduitController
        );
        assembly {
            return(add(returnData, 32), mload(returnData))
        }
    }

    function return_string(string memory value0) internal pure {
        bytes memory returnData = abi.encode(value0);
        assembly {
            return(add(returnData, 32), mload(returnData))
        }
    }
}
