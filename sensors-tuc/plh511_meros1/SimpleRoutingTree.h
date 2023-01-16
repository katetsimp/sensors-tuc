#ifndef SIMPLEROUTINGTREE_H
#define SIMPLEROUTINGTREE_H


enum{
        MAX_Ch=20, 
        D=9,
	SENDER_QUEUE_SIZE=5,
	RECEIVER_QUEUE_SIZE=3,
	AM_SIMPLEROUTINGTREEMSG=22,
	AM_ROUTINGMSG=22,
	AM_MSG=12,
	SEND_CHECK_MILLIS=70000,
	TIMER_PERIOD_MILLI=30000,
	TIMER_FAST_PERIOD=200,
	TIMER_LEDS_MILLI=1000,
        MAX=1,
        COUNT=2,
};
/*uint16_t AM_ROUTINGMSG=AM_SIMPLEROUTINGTREEMSG;
uint16_t AM_NOTIFYPARENTMSG=AM_SIMPLEROUTINGTREEMSG;
*/
typedef nx_struct RoutingMsg
{
	nx_uint16_t senderID;
	nx_uint8_t depth;
} RoutingMsg;

typedef nx_struct NotifyParentMsg
{
	nx_uint16_t senderID;
	nx_uint16_t parentID;
	nx_uint8_t depth;
} NotifyParentMsg;
typedef nx_struct childInfo
{
nx_uint16_t ChID;
nx_uint8_t max;
nx_uint8_t count;


}childInfo;
typedef nx_struct Onemessage
{
nx_uint8_t m;
}Onemessage;
typedef nx_struct routingwith2func
{
nx_uint8_t depth;
nx_uint8_t choice0;
nx_uint8_t choice1;
nx_uint8_t tct;

}routingwith2func;
typedef nx_struct routingwith1func
{
nx_uint8_t depth;
nx_uint8_t choice0;
nx_uint8_t tct;

}routingwith1func;
typedef nx_struct Twomess {
nx_uint8_t m1;
nx_uint8_t m2;
nx_uint8_t measurmentsfield[2];


}Twomess;
typedef nx_struct counter
{
nx_uint8_t c1;
}counter;
#endif
