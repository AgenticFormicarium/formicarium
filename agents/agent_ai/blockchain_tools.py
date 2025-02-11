import json
import sys
import os
from pathlib import Path
from cdp.smart_contract import SmartContract
from langchain.tools import tool

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "../..")))
import agents.agent_ai.config as config

# Load the ABI from the contract's compiled JSON file
with open("/home/luka/projects/formicarium/blockchain/artifacts/contracts/Formicarium.sol/Formicarium.json") as abi_file:
    contract_data = json.load(abi_file)
    abi = contract_data["abi"]
    
# Debug: Print the ABI and contract address
print("ABI:", abi)
print("Contract Address:", config.FORMICARIUM_SC_ADDRESS)
print("Network ID:", config.NETWORK_ID)

@tool("get_all_printers")
def get_all_printers() -> str:
    """
    Retrieve all registered printers from the smart contract.
    """
    try:
        printers = SmartContract.read(
            config.NETWORK_ID,
            config.FORMICARIUM_SC_ADDRESS,
            "getAllPrinters",
            abi
        )
        return str(json.dumps(printers, indent=2))
    except Exception as e:
        return f"Failed to fetch printers: {str(e)}"
    
@tool("register_printer", return_direct=True)
def register_printer(printer_details: str) -> str:
    """
    Register a new printer with the given details.
    """
    try:
        SmartContract.write(
            config.NETWORK_ID,
            config.FORMICARIUM_SC_ADDRESS,
            "registerPrinter",
            abi,
            [printer_details]
        )
        return f"Printer '{printer_details}' successfully registered."
    except Exception as e:
        return f"Failed to register printer: {str(e)}"
    
@tool("create_order", return_direct=True)
def create_order(order_id: str, printer_id: str, minimal_price: int, actual_price: int, duration: int) -> str:
    """
    Create an order with the provided details.
    """
    try:
        SmartContract.write(
            config.NETWORK_ID,
            config.FORMICARIUM_SC_ADDRESS,
            "createOrder",
            abi,
            [order_id, printer_id, minimal_price, actual_price, duration]
        )
        return f"Order {order_id} successfully created."
    except Exception as e:
        return f"Failed to create order: {str(e)}"
    
@tool("get_active_orders", return_direct=True)
def get_active_orders() -> str:
    """
    Retrieve the active orders for the current user.
    """
    try:
        active_orders = SmartContract.read(
            config.NETWORK_ID,
            config.FORMICARIUM_SC_ADDRESS,
            "getActiveOrders",
            abi
        )
        return json.dumps(active_orders, indent=2)
    except Exception as e:
        return f"Failed to fetch active orders: {str(e)}"
    
@tool("sign_order", return_direct=True)
def sign_order(order_id: str) -> str:
    """
    Sign an order as a printer.
    """
    try:
        SmartContract.write(
            config.NETWORK_ID,
            config.FORMICARIUM_SC_ADDRESS,
            "signOrder",
            abi,
            [order_id]
        )
        return f"Order {order_id} successfully signed."
    except Exception as e:
        return f"Failed to sign order: {str(e)}"
    
@tool("execute_new_order", return_direct=True)
def execute_new_order() -> str:
    """
    Execute a new order as a printer.
    """
    try:
        SmartContract.write(
            config.NETWORK_ID,
            config.FORMICARIUM_SC_ADDRESS,
            "executeNewOrder",
            abi,
            []
        )
        return f"New order successfully executed."
    except Exception as e:
        return f"Failed to execute new order: {str(e)}"


@tool("complete_order_provider", return_direct=True)
def complete_order_provider(order_id: str) -> str:
    """
    Complete the order as the provider.
    """
    try:
        SmartContract.write(
            config.NETWORK_ID,
            config.FORMICARIUM_SC_ADDRESS,
            "completeOrderProvider",
            abi,
            [order_id]
        )
        return f"Order {order_id} successfully completed by the provider."
    except Exception as e:
        return f"Failed to complete order: {str(e)}"


@tool("report_uncomplete_order", return_direct=True)
def report_uncomplete_order(order_id: str) -> str:
    """
    Report the order as incomplete by the customer.
    """
    try:
        SmartContract.write(
            config.NETWORK_ID,
            config.FORMICARIUM_SC_ADDRESS,
            "reportUncompleteOrder",
            abi,
            [order_id]
        )
        return f"Order {order_id} successfully reported as incomplete."
    except Exception as e:
        return f"Failed to report uncomplete order: {str(e)}"

@tool("refund_order_request", return_direct=True)
def refund_order_request(order_id: str) -> str:
    """
    Request a refund for an order as a customer.
    """
    try:
        SmartContract.write(
            config.NETWORK_ID,
            config.FORMICARIUM_SC_ADDRESS,
            "refundOrderRequest",
            abi,
            [order_id]
        )
        return f"Refund request for order {order_id} successfully processed."
    except Exception as e:
        return f"Failed to request refund: {str(e)}"

@tool("transfer_funds_provider", return_direct=True)
def transfer_funds_provider(order_id: str) -> str:
    """
    Transfer funds to the provider after the order is completed.
    """
    try:
        SmartContract.write(
            config.NETWORK_ID,
            config.FORMICARIUM_SC_ADDRESS,
            "transferFundsProivder",
            abi,
            [order_id]
        )
        return f"Funds for order {order_id} successfully transferred to provider."
    except Exception as e:
        return f"Failed to transfer funds: {str(e)}"



if __name__ == "__main__":
    print(get_all_printers.run(""))

