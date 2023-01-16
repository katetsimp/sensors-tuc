#include "SimpleRoutingTree.h"

configuration SRTreeAppC @safe() { }
implementation{
	components SRTreeC;

#if defined(DELUGE) //defined(DELUGE_BASESTATION) || defined(DELUGE_LIGHT_BASESTATION)
	components DelugeC;
#endif

#ifdef PRINTFDBG_MODE
		components PrintfC;
#endif
	components MainC, ActiveMessageC,RandomC;
	
	components new TimerMilliC() as RoutingMsgTimerC;
        components new TimerMilliC() as SendMsgTimerC;
         components new TimerMilliC() as periodTimerC;
	 components new TimerMilliC() as  counterTimerC;
	
	components new AMSenderC(AM_ROUTINGMSG) as RoutingSenderC;
	components new AMReceiverC(AM_ROUTINGMSG) as RoutingReceiverC;
	components new AMSenderC(AM_MSG) as MessSenderC;
	components new AMReceiverC(AM_MSG) as MessReceiveC;

	components new PacketQueueC(SENDER_QUEUE_SIZE) as RoutingSendQueueC;
	components new PacketQueueC(RECEIVER_QUEUE_SIZE) as RoutingReceiveQueueC;
	components new PacketQueueC(SENDER_QUEUE_SIZE) as MessSendQueueC;
	components new PacketQueueC(RECEIVER_QUEUE_SIZE) as MessReceiveQueueC;
	SRTreeC.randomN->RandomC;
        SRTreeC.Seed->RandomC.SeedInit;

	SRTreeC.Boot->MainC.Boot;
	
	SRTreeC.RadioControl -> ActiveMessageC;
	
	
	
	SRTreeC.RoutingMsgTimer->RoutingMsgTimerC;
        SRTreeC.SendMsgTimer->SendMsgTimerC;
        SRTreeC.periodTimer->periodTimerC;
        SRTreeC.counterTimer->counterTimerC;
	
	
	SRTreeC.RoutingPacket->RoutingSenderC.Packet;
	SRTreeC.RoutingAMPacket->RoutingSenderC.AMPacket;
	SRTreeC.RoutingAMSend->RoutingSenderC.AMSend;
	SRTreeC.RoutingReceive->RoutingReceiverC.Receive;
	
	SRTreeC.MessPacket->MessSenderC.Packet;
	SRTreeC.MessAMPacket->MessSenderC.AMPacket;
	SRTreeC.MessAMSend->MessSenderC.AMSend;
	SRTreeC.MessReceive->MessReceiveC.Receive;
	

	SRTreeC.RoutingSendQueue->RoutingSendQueueC;
	SRTreeC.RoutingReceiveQueue->RoutingReceiveQueueC;
	SRTreeC.MessSendQueue->MessSendQueueC;
	SRTreeC.MessReceiveQueue->MessReceiveQueueC;
	
}
