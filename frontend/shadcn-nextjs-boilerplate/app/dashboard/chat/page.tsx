"use client";
import Chat from "@/components/chat/chat";
import OrderSummary from "@/components/card/OrderSummary";
import ApproveCard from "@/components/card/Approve";

export default function ChatPage() {
    return (
        <div className="grid grid-cols-2 gap-8">
            {/* Left Column (Chat) */}
            <div className="bg-transparent md:col-span-1 p-0 rounded-lg shadow-md">
                <Chat responses={[
                    "Hello! How can I help you today?",
                    "I'm just a simulated AI, but I can respond with predefined messages.",
                    "Tell me more about what you're working on!",
                    "That sounds interesting! Could you elaborate?",
                ]} />
            </div>

            {/* Right Column (Approval & Order Summary) */}
            <div className="md:col-span-1 w-6/7 max-w-lg min-w-[400px] flex flex-col space-y-4">
                <ApproveCard imageSrc="/approve2DBackground.png" onApprove={() => alert("Approved")}
                             onReject={() => alert("Rejected")} text="Use chat to generate an image?"/>
                <ApproveCard imageSrc="/approveSTLBackground.png" onApprove={() => alert("Approved")}
                             onReject={() => alert("Rejected")} text="You need an image to generate a model?"/>
                <OrderSummary onApprove={() => alert("Order Confirmed")} dimensions={[10, 20, 30]} quantity={5}
                              price={100} fee={10}/>
            </div>
        </div>
    );
}
