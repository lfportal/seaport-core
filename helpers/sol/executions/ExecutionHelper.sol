// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {
    AmountDeriverHelper
} from "../lib/fulfillment/AmountDeriverHelper.sol";

import { AdvancedOrderLib } from "../lib/AdvancedOrderLib.sol";

import {
    AdvancedOrder,
    CriteriaResolver,
    Execution,
    Fulfillment,
    FulfillmentComponent,
    Order,
    ReceivedItem,
    SpentItem
} from "../../../lib/ConsiderationStructs.sol";

import { ItemType, Side } from "../../../lib/ConsiderationEnums.sol";

import {
    FulfillmentDetails,
    OrderDetails
} from "../fulfillments/lib/Structs.sol";

/**
 * @dev Helper contract for deriving explicit and executions from orders and
 *      fulfillment details
 *
 * @dev TODO: move to the tests folder? not really useful for normal scripting
 */
library ExecutionHelper {
    using AdvancedOrderLib for AdvancedOrder[];

    error InsufficientNativeTokensSupplied();

    /**
     * @dev get explicit and implicit executions for a fulfillAvailable call
     *
     * @param fulfillmentDetails        the fulfillment details
     * @param offerFulfillments         2d array of offer fulfillment components
     * @param considerationFulfillments 2d array of consideration fulfillment
     * @param nativeTokensSupplied      the amount of native tokens supplied to
     *                                  the fulfillAvailable call
     *
     * @return explicitExecutions the explicit executions
     * @return implicitExecutions the implicit executions (unspecified offer
     *                            items)
     */
    function getFulfillAvailableExecutions(
        FulfillmentDetails memory fulfillmentDetails,
        FulfillmentComponent[][] memory offerFulfillments,
        FulfillmentComponent[][] memory considerationFulfillments,
        uint256 nativeTokensSupplied,
        bool[] memory availableOrders
    )
        public
        pure
        returns (
            Execution[] memory explicitExecutions,
            Execution[] memory implicitExecutions,
            uint256 nativeTokensReturned
        )
    {
        explicitExecutions = processExplicitExecutionsFromAggregatedComponents(
            fulfillmentDetails,
            offerFulfillments,
            considerationFulfillments,
            availableOrders
        );

        implicitExecutions = processImplicitOfferExecutions(
            fulfillmentDetails,
            availableOrders
        );

        nativeTokensReturned = _handleExcessNativeTokens(
            fulfillmentDetails,
            explicitExecutions,
            implicitExecutions,
            nativeTokensSupplied
        );
    }

    /**
     * @dev Process an array of fulfillments into an array of explicit and
     *         implicit executions.
     *
     * @param fulfillmentDetails The fulfillment details.
     * @param fulfillments An array of fulfillments.
     * @param nativeTokensSupplied the amount of native tokens supplied
     *
     * @return explicitExecutions The explicit executions
     * @return implicitExecutions The implicit executions
     */
    function getMatchExecutions(
        FulfillmentDetails memory fulfillmentDetails,
        Fulfillment[] memory fulfillments,
        uint256 nativeTokensSupplied
    )
        internal
        pure
        returns (
            Execution[] memory explicitExecutions,
            Execution[] memory implicitExecutions,
            uint256 nativeTokensReturned
        )
    {
        explicitExecutions = new Execution[](fulfillments.length);

        uint256 filteredExecutions = 0;

        for (uint256 i = 0; i < fulfillments.length; i++) {
            Execution memory execution = processExecutionFromFulfillment(
                fulfillmentDetails,
                fulfillments[i]
            );

            if (
                execution.item.recipient == execution.offerer &&
                execution.item.itemType != ItemType.NATIVE
            ) {
                filteredExecutions++;
            } else {
                explicitExecutions[i - filteredExecutions] = execution;
            }
        }

        // If some number of executions have been filtered...
        if (filteredExecutions != 0) {
            // reduce the total length of the executions array.
            assembly {
                mstore(
                    explicitExecutions,
                    sub(mload(explicitExecutions), filteredExecutions)
                )
            }
        }

        bool[] memory availableOrders = new bool[](
            fulfillmentDetails.orders.length
        );
        for (uint256 i = 0; i < fulfillmentDetails.orders.length; ++i) {
            availableOrders[i] = true;
        }

        implicitExecutions = processImplicitOfferExecutions(
            fulfillmentDetails,
            availableOrders
        );

        nativeTokensReturned = _handleExcessNativeTokens(
            fulfillmentDetails,
            explicitExecutions,
            implicitExecutions,
            nativeTokensSupplied
        );
    }

    function processExcessNativeTokens(
        Execution[] memory explicitExecutions,
        Execution[] memory implicitExecutions,
        uint256 nativeTokensSupplied
    ) internal pure returns (uint256 excessNativeTokens) {
        excessNativeTokens = nativeTokensSupplied;
        for (uint256 i; i < explicitExecutions.length; i++) {
            ReceivedItem memory item = explicitExecutions[i].item;
            if (item.itemType == ItemType.NATIVE) {
                excessNativeTokens -= item.amount;
            }
        }
        for (uint256 i; i < implicitExecutions.length; i++) {
            ReceivedItem memory item = implicitExecutions[i].item;
            if (item.itemType == ItemType.NATIVE) {
                excessNativeTokens -= item.amount;
            }
        }
    }

    /**
     * @dev Return executions for fulfilOrder and fulfillAdvancedOrder.
     */
    function getStandardExecutions(
        OrderDetails memory orderDetails,
        address fulfiller,
        bytes32 fulfillerConduitKey,
        address recipient,
        uint256 nativeTokensSupplied,
        address seaport
    ) public pure returns (Execution[] memory implicitExecutions) {
        uint256 excessNativeTokens = nativeTokensSupplied;

        implicitExecutions = new Execution[](
            orderDetails.offer.length + orderDetails.consideration.length + 1
        );

        uint256 executionIndex = 0;

        for (uint256 i = 0; i < orderDetails.offer.length; i++) {
            if (orderDetails.offer[i].itemType == ItemType.NATIVE) {
                excessNativeTokens += orderDetails.offer[i].amount;
            }
            implicitExecutions[executionIndex] = Execution({
                offerer: orderDetails.offerer,
                conduitKey: orderDetails.conduitKey,
                item: ReceivedItem({
                    itemType: orderDetails.offer[i].itemType,
                    token: orderDetails.offer[i].token,
                    identifier: orderDetails.offer[i].identifier,
                    amount: orderDetails.offer[i].amount,
                    recipient: payable(recipient)
                })
            });
            executionIndex++;
        }

        for (uint256 i = 0; i < orderDetails.consideration.length; i++) {
            if (orderDetails.consideration[i].itemType == ItemType.NATIVE) {
                excessNativeTokens -= orderDetails.consideration[i].amount;
            }
            implicitExecutions[executionIndex] = Execution({
                offerer: fulfiller,
                conduitKey: fulfillerConduitKey,
                item: orderDetails.consideration[i]
            });
            executionIndex++;
        }

        if (excessNativeTokens > 0) {
            implicitExecutions[executionIndex] = Execution({
                offerer: seaport,
                conduitKey: bytes32(0),
                item: ReceivedItem({
                    itemType: ItemType.NATIVE,
                    token: address(0),
                    identifier: 0,
                    amount: excessNativeTokens,
                    recipient: payable(fulfiller)
                })
            });
        } else {
            // Reduce length of the implicit executions array by one.
            assembly {
                mstore(implicitExecutions, sub(mload(implicitExecutions), 1))
            }
        }
    }

    /**
     * @dev return executions for fulfillBasicOrder and
     *      fulfillBasicOrderEfficient.
     */
    function getBasicExecutions(
        OrderDetails memory orderDetails,
        address fulfiller,
        bytes32 fulfillerConduitKey,
        uint256 nativeTokensSupplied,
        address seaport
    ) public pure returns (Execution[] memory implicitExecutions) {
        if (orderDetails.offer.length != 1) {
            revert("not a basic order");
        }

        if (orderDetails.offer[0].itemType == ItemType.ERC20) {
            require(nativeTokensSupplied == 0, "native tokens not allowed");
            require(orderDetails.consideration.length > 0, "no items received");

            implicitExecutions = new Execution[](
                1 + orderDetails.consideration.length
            );

            implicitExecutions[0] = Execution({
                offerer: fulfiller,
                conduitKey: fulfillerConduitKey,
                item: orderDetails.consideration[0]
            });

            uint256 additionalAmounts = 0;

            for (uint256 i = 1; i < orderDetails.consideration.length; i++) {
                implicitExecutions[i] = Execution({
                    offerer: orderDetails.offerer,
                    conduitKey: orderDetails.conduitKey,
                    item: orderDetails.consideration[i]
                });
                additionalAmounts += orderDetails.consideration[i].amount;
            }

            implicitExecutions[orderDetails.consideration.length] = Execution({
                offerer: orderDetails.offerer,
                conduitKey: orderDetails.conduitKey,
                item: ReceivedItem({
                    itemType: orderDetails.offer[0].itemType,
                    token: orderDetails.offer[0].token,
                    identifier: orderDetails.offer[0].identifier,
                    amount: orderDetails.offer[0].amount - additionalAmounts,
                    recipient: payable(fulfiller)
                })
            });
        } else {
            // use existing function but order of executions has to be shifted
            // so second execution is returned last in cases where no returned native tokens
            // or second to last in cases where returned native tokens
            Execution[] memory standardExecutions = getStandardExecutions(
                orderDetails,
                fulfiller,
                fulfillerConduitKey,
                fulfiller,
                nativeTokensSupplied,
                seaport
            );

            require(standardExecutions.length > 1, "too short for basic order");

            implicitExecutions = new Execution[](standardExecutions.length);
            implicitExecutions[0] = standardExecutions[0];

            if (
                standardExecutions.length >
                1 + orderDetails.consideration.length
            ) {
                for (uint256 i = 2; i < implicitExecutions.length - 1; i++) {
                    implicitExecutions[i - 1] = standardExecutions[i];
                }
                implicitExecutions[
                    implicitExecutions.length - 2
                ] = standardExecutions[1];
                implicitExecutions[
                    implicitExecutions.length - 1
                ] = standardExecutions[implicitExecutions.length - 1];
            } else {
                for (uint256 i = 2; i < implicitExecutions.length; i++) {
                    implicitExecutions[i - 1] = standardExecutions[i];
                }
                implicitExecutions[
                    implicitExecutions.length - 1
                ] = standardExecutions[1];
            }
        }
    }

    /**
     * @dev Get the item and recipient for a given fulfillment component.
     *
     * @param fulfillmentDetails The order fulfillment details
     * @param offerRecipient     The offer recipient
     * @param component          The fulfillment component
     * @param side               The side of the order
     *
     * @return item          The item
     * @return trueRecipient The actual recipient
     */
    function getItemAndRecipient(
        FulfillmentDetails memory fulfillmentDetails,
        address payable offerRecipient,
        FulfillmentComponent memory component,
        Side side
    )
        internal
        pure
        returns (SpentItem memory item, address payable trueRecipient)
    {
        OrderDetails memory details = fulfillmentDetails.orders[
            component.orderIndex
        ];

        if (side == Side.OFFER) {
            item = details.offer[component.itemIndex];
            trueRecipient = offerRecipient;
        } else {
            ReceivedItem memory _item = details.consideration[
                component.itemIndex
            ];
            // cast to SpentItem
            assembly {
                item := _item
            }
            trueRecipient = _item.recipient;
        }
    }

    /**
     * @dev Process the aggregated fulfillment components for a given side of an
     *      order.
     *
     * @param fulfillmentDetails   The order fulfillment details
     * @param offerRecipient       The recipient for any offer items. Note: may
     *                             not be FulfillmentDetails' recipient, eg,
     *                             when processing matchOrders fulfillments
     * @param aggregatedComponents The aggregated fulfillment components
     * @param side                 The side of the order
     *
     * @return The execution
     */
    function processExecutionFromAggregatedFulfillmentComponents(
        FulfillmentDetails memory fulfillmentDetails,
        address payable offerRecipient,
        FulfillmentComponent[] memory aggregatedComponents,
        Side side
    ) internal pure returns (Execution memory) {
        // aggregate the amounts of each item
        uint256 aggregatedAmount;
        for (uint256 j = 0; j < aggregatedComponents.length; j++) {
            (SpentItem memory item, ) = getItemAndRecipient(
                fulfillmentDetails,
                offerRecipient,
                aggregatedComponents[j],
                side
            );
            aggregatedAmount += item.amount;
        }

        // use the first fulfillment component to get the order details
        FulfillmentComponent memory first = aggregatedComponents[0];
        (
            SpentItem memory firstItem,
            address payable trueRecipient
        ) = getItemAndRecipient(
                fulfillmentDetails,
                offerRecipient,
                first,
                side
            );
        OrderDetails memory details = fulfillmentDetails.orders[
            first.orderIndex
        ];

        return
            Execution({
                offerer: side == Side.OFFER
                    ? details.offerer
                    : fulfillmentDetails.fulfiller,
                conduitKey: side == Side.OFFER
                    ? details.conduitKey
                    : fulfillmentDetails.fulfillerConduitKey,
                item: ReceivedItem({
                    itemType: firstItem.itemType,
                    token: firstItem.token,
                    identifier: firstItem.identifier,
                    amount: aggregatedAmount,
                    recipient: trueRecipient
                })
            });
    }

    /**
     * @dev Process explicit executions from 2d aggregated fulfillAvailable
     *      fulfillment components arrays. Note that amounts on OrderDetails are
     *      modified in-place during fulfillment processing.
     *
     * @param fulfillmentDetails      The fulfillment details
     * @param offerComponents         The offer components
     * @param considerationComponents The consideration components
     *
     * @return explicitExecutions The explicit executions
     */
    function processExplicitExecutionsFromAggregatedComponents(
        FulfillmentDetails memory fulfillmentDetails,
        FulfillmentComponent[][] memory offerComponents,
        FulfillmentComponent[][] memory considerationComponents,
        bool[] memory availableOrders
    ) internal pure returns (Execution[] memory explicitExecutions) {
        explicitExecutions = new Execution[](
            offerComponents.length + considerationComponents.length
        );

        uint256 filteredExecutions = 0;

        // process offer components
        // iterate over each array of fulfillment components
        for (uint256 i = 0; i < offerComponents.length; i++) {
            FulfillmentComponent[]
                memory aggregatedComponents = offerComponents[i];

            // aggregate & zero-out the amounts of each offer item
            uint256 aggregatedAmount;
            for (uint256 j = 0; j < aggregatedComponents.length; j++) {
                FulfillmentComponent memory component = aggregatedComponents[j];

                if (!availableOrders[component.orderIndex]) {
                    continue;
                }

                OrderDetails memory offerOrderDetails = fulfillmentDetails
                    .orders[component.orderIndex];

                if (component.itemIndex < offerOrderDetails.offer.length) {
                    SpentItem memory item = offerOrderDetails.offer[
                        component.itemIndex
                    ];

                    aggregatedAmount += item.amount;

                    item.amount = 0;
                }
            }

            if (aggregatedAmount == 0) {
                filteredExecutions++;
                continue;
            }

            // use the first fulfillment component to get the order details
            FulfillmentComponent memory first = aggregatedComponents[0];
            OrderDetails memory details = fulfillmentDetails.orders[
                first.orderIndex
            ];
            SpentItem memory firstItem = details.offer[first.itemIndex];

            if (
                fulfillmentDetails.recipient == details.offerer &&
                firstItem.itemType != ItemType.NATIVE
            ) {
                filteredExecutions++;
            } else {
                explicitExecutions[i - filteredExecutions] = Execution({
                    offerer: details.offerer,
                    conduitKey: details.conduitKey,
                    item: ReceivedItem({
                        itemType: firstItem.itemType,
                        token: firstItem.token,
                        identifier: firstItem.identifier,
                        amount: aggregatedAmount,
                        recipient: fulfillmentDetails.recipient
                    })
                });
            }
        }

        // process consideration components
        // iterate over each array of fulfillment components
        for (uint256 i; i < considerationComponents.length; i++) {
            FulfillmentComponent[]
                memory aggregatedComponents = considerationComponents[i];

            // aggregate & zero-out the amounts of each offer item
            uint256 aggregatedAmount;
            for (uint256 j = 0; j < aggregatedComponents.length; j++) {
                FulfillmentComponent memory component = aggregatedComponents[j];

                if (!availableOrders[component.orderIndex]) {
                    continue;
                }

                OrderDetails
                    memory considerationOrderDetails = fulfillmentDetails
                        .orders[component.orderIndex];

                if (
                    component.itemIndex <
                    considerationOrderDetails.consideration.length
                ) {
                    ReceivedItem memory item = considerationOrderDetails
                        .consideration[component.itemIndex];

                    aggregatedAmount += item.amount;

                    item.amount = 0;
                }
            }

            if (aggregatedAmount == 0) {
                filteredExecutions++;
                continue;
            }

            // use the first fulfillment component to get the order details
            FulfillmentComponent memory first = aggregatedComponents[0];
            OrderDetails memory details = fulfillmentDetails.orders[
                first.orderIndex
            ];
            ReceivedItem memory firstItem = details.consideration[
                first.itemIndex
            ];

            if (
                firstItem.recipient == fulfillmentDetails.fulfiller &&
                firstItem.itemType != ItemType.NATIVE
            ) {
                filteredExecutions++;
            } else {
                explicitExecutions[
                    i + offerComponents.length - filteredExecutions
                ] = Execution({
                    offerer: fulfillmentDetails.fulfiller,
                    conduitKey: fulfillmentDetails.fulfillerConduitKey,
                    item: ReceivedItem({
                        itemType: firstItem.itemType,
                        token: firstItem.token,
                        identifier: firstItem.identifier,
                        amount: aggregatedAmount,
                        recipient: firstItem.recipient
                    })
                });
            }
        }

        // If some number of executions have been filtered...
        if (filteredExecutions != 0) {
            // reduce the total length of the executions array.
            assembly {
                mstore(
                    explicitExecutions,
                    sub(mload(explicitExecutions), filteredExecutions)
                )
            }
        }
    }

    /**
     * @dev Process an array of *sorted* fulfillment components into an array of
     *      executions. Note that components must be sorted.
     *
     * @param orderDetails The order details
     * @param components   The fulfillment components
     * @param recipient    The recipient of implicit executions
     *
     * @return executions The executions
     */
    function processExecutionsFromIndividualOfferFulfillmentComponents(
        OrderDetails[] memory orderDetails,
        address payable recipient,
        FulfillmentComponent[] memory components
    ) internal pure returns (Execution[] memory executions) {
        executions = new Execution[](components.length);

        for (uint256 i = 0; i < components.length; i++) {
            FulfillmentComponent memory component = components[i];
            OrderDetails memory details = orderDetails[component.orderIndex];
            SpentItem memory item = details.offer[component.itemIndex];
            executions[i] = Execution({
                offerer: details.offerer,
                conduitKey: details.conduitKey,
                item: ReceivedItem({
                    itemType: item.itemType,
                    token: item.token,
                    identifier: item.identifier,
                    amount: item.amount,
                    recipient: recipient
                })
            });
        }
    }

    /**
     * @dev Generate implicit Executions for a set of orders by getting all
     *      offer items that are not fully spent as part of a fulfillment.
     *
     * @param fulfillmentDetails fulfillment details
     *
     * @return implicitExecutions The implicit executions
     */
    function processImplicitOfferExecutions(
        FulfillmentDetails memory fulfillmentDetails,
        bool[] memory availableOrders
    ) internal pure returns (Execution[] memory implicitExecutions) {
        OrderDetails[] memory orderDetails = fulfillmentDetails.orders;

        // Get the maximum possible number of implicit executions.
        uint256 maxPossible = 1;
        for (uint256 i = 0; i < orderDetails.length; ++i) {
            if (availableOrders[i]) {
                maxPossible += orderDetails[i].offer.length;
            }
        }

        // Insert an implicit execution for each non-zero offer item.
        implicitExecutions = new Execution[](maxPossible);
        uint256 insertionIndex = 0;
        for (uint256 i = 0; i < orderDetails.length; ++i) {
            if (!availableOrders[i]) {
                continue;
            }

            OrderDetails memory details = orderDetails[i];
            for (uint256 j; j < details.offer.length; ++j) {
                SpentItem memory item = details.offer[j];
                if (item.amount != 0) {
                    // Insert the item and increment insertion index.
                    implicitExecutions[insertionIndex++] = Execution({
                        offerer: details.offerer,
                        conduitKey: details.conduitKey,
                        item: ReceivedItem({
                            itemType: item.itemType,
                            token: item.token,
                            identifier: item.identifier,
                            amount: item.amount,
                            recipient: fulfillmentDetails.recipient
                        })
                    });
                }
            }
        }

        // Set the final length of the implicit executions array.
        // Leave space for possible excess native token return.
        assembly {
            mstore(implicitExecutions, add(insertionIndex, 1))
        }
    }

    /**
     * @dev Process a Fulfillment into an Execution
     *
     * @param fulfillmentDetails fulfillment details
     * @param fulfillment A Fulfillment.
     *
     * @return An Execution.
     */
    function processExecutionFromFulfillment(
        FulfillmentDetails memory fulfillmentDetails,
        Fulfillment memory fulfillment
    ) internal pure returns (Execution memory) {
        // aggregate & zero-out the amounts of each offer item
        uint256 aggregatedOfferAmount;
        for (uint256 j = 0; j < fulfillment.offerComponents.length; j++) {
            FulfillmentComponent memory component = fulfillment.offerComponents[
                j
            ];

            OrderDetails memory details = fulfillmentDetails.orders[
                component.orderIndex
            ];

            if (component.itemIndex < details.offer.length) {
                SpentItem memory offerSpentItem = details.offer[
                    component.itemIndex
                ];

                aggregatedOfferAmount += offerSpentItem.amount;

                offerSpentItem.amount = 0;
            }
        }

        // aggregate & zero-out the amounts of each offer item
        uint256 aggregatedConsiderationAmount;
        for (
            uint256 j = 0;
            j < fulfillment.considerationComponents.length;
            j++
        ) {
            FulfillmentComponent memory component = fulfillment
                .considerationComponents[j];

            OrderDetails memory details = fulfillmentDetails.orders[
                component.orderIndex
            ];

            if (component.itemIndex < details.consideration.length) {
                ReceivedItem memory considerationSpentItem = details
                    .consideration[component.itemIndex];

                aggregatedConsiderationAmount += considerationSpentItem.amount;

                considerationSpentItem.amount = 0;
            }
        }

        // Get the first item on each side
        FulfillmentComponent memory firstOfferComponent = fulfillment
            .offerComponents[0];
        OrderDetails memory sourceOrder = fulfillmentDetails.orders[
            firstOfferComponent.orderIndex
        ];

        FulfillmentComponent memory firstConsiderationComponent = fulfillment
            .considerationComponents[0];
        ReceivedItem memory item = fulfillmentDetails
            .orders[firstConsiderationComponent.orderIndex]
            .consideration[firstConsiderationComponent.itemIndex];

        // put back any extra (TODO: put it on first *in-range* item)
        uint256 amount = aggregatedOfferAmount;
        if (aggregatedOfferAmount > aggregatedConsiderationAmount) {
            sourceOrder
                .offer[firstOfferComponent.itemIndex]
                .amount += (aggregatedOfferAmount -
                aggregatedConsiderationAmount);
            amount = aggregatedConsiderationAmount;
        } else if (aggregatedOfferAmount < aggregatedConsiderationAmount) {
            item.amount += (aggregatedConsiderationAmount -
                aggregatedOfferAmount);
        }

        return
            Execution({
                offerer: sourceOrder.offerer,
                conduitKey: sourceOrder.conduitKey,
                item: ReceivedItem({
                    itemType: item.itemType,
                    token: item.token,
                    identifier: item.identifier,
                    amount: amount,
                    recipient: item.recipient
                })
            });
    }

    /**
     * @dev Process excess native tokens.  If there are excess native tokens,
     *      insert an implicit execution at the end of the implicitExecutions
     *      array. If not, reduce the length of the implicitExecutions array.
     *
     * @param fulfillmentDetails fulfillment details
     * @param explicitExecutions explicit executions
     * @param implicitExecutions implicit executions
     * @param nativeTokensSupplied native tokens sent
     */
    function _handleExcessNativeTokens(
        FulfillmentDetails memory fulfillmentDetails,
        Execution[] memory explicitExecutions,
        Execution[] memory implicitExecutions,
        uint256 nativeTokensSupplied
    ) internal pure returns (uint256 excessNativeTokens) {
        excessNativeTokens = processExcessNativeTokens(
            explicitExecutions,
            implicitExecutions,
            nativeTokensSupplied
        );

        if (excessNativeTokens > 0) {
            implicitExecutions[implicitExecutions.length - 1] = Execution({
                offerer: fulfillmentDetails.seaport,
                conduitKey: bytes32(0),
                item: ReceivedItem({
                    itemType: ItemType.NATIVE,
                    token: address(0),
                    identifier: 0,
                    amount: excessNativeTokens,
                    recipient: fulfillmentDetails.fulfiller
                })
            });
        } else {
            // Reduce length of the implicit executions array by one.
            assembly {
                mstore(implicitExecutions, sub(mload(implicitExecutions), 1))
            }
        }
    }
}