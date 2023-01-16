#include "SimpleRoutingTree.h"
#ifdef PRINTFDBG_MODE
    #include "printf.h"
#endif

module SRTreeC
{
    uses interface Boot;
   
    uses interface SplitControl as RadioControl;


    uses interface Packet as RoutingPacket;
    uses interface AMSend as RoutingAMSend;
    uses interface AMPacket as RoutingAMPacket;
   
    uses interface AMSend as MessAMSend;
    uses interface AMPacket as MessAMPacket;
    uses interface Packet as MessPacket;


   
    uses interface Timer<TMilli> as RoutingMsgTimer;
        uses interface Timer<TMilli> as SendMsgTimer;
        uses interface Timer<TMilli> as periodTimer;
         uses interface Timer<TMilli> as counterTimer;
   
   
    uses interface Receive as RoutingReceive;
    uses interface Receive as MessReceive;
   
    uses interface PacketQueue as RoutingSendQueue;
    uses interface PacketQueue as RoutingReceiveQueue;
   
    uses interface PacketQueue as MessSendQueue;
    uses interface PacketQueue as MessReceiveQueue;
        uses interface Random as randomN;
        uses interface ParameterInit<uint16_t> as Seed;
}
implementation
{ // hold current round
    uint16_t  roundCounter;
   // routing message and mess for sending
    message_t radioRoutingSendPkt;
    message_t radioMessSendPkt;
   
   
   
   
   

   
   
    childInfo Children[MAX_Ch];
        uint8_t curdepth;
        uint32_t counter;
        uint8_t measurment;
        uint8_t previousCalc;
  
         uint8_t previousCalc1;
         uint8_t prev_measurment;
         
         uint16_t parentID;
        //make a tct for tina ext
        uint8_t tct;
       //max_count_max&count
        uint8_t choice[2];
    bool finishedRouting =FALSE;
    task void sendRoutingTask();
    task void sendMessTask();
    task void receiveRoutingTask();
    task void receiveMessTask();
    //need a function to do our calculation about max and count
         uint8_t calculateF(uint8_t operation,uint8_t m);
        //need init functions
        void InitchildArr();
        void InitializeMaxCountAr();
       
       

       
      

        void InitchildArr(){
        uint8_t j;
         for(j=0;j<MAX_Ch;j++){
         Children[j].ChID=0;
         Children[j].max=0;
         Children[j].count=0;
         dbg("Tests","Initialize child\n");
                             }

       
        }

        void InitializeMaxCountAr(){
        uint8_t j;
       for(j=0;j<2;j++){
         choice[j]=0;
       }
   
       
 
                                    }
   
    event void Boot.booted()
    {
         //initialisation
        call RadioControl.start();
                roundCounter=0;
       
        InitializeMaxCountAr(); 
        
       
            if(TOS_NODE_ID==0)
        {
     
            curdepth=0;
            parentID=0;
            dbg("Boot", "curdepth = %d  ,  parentID= %d \n", curdepth , parentID);

        }
        else
        {
            curdepth=-1;
            parentID=-1;
            dbg("Boot", "curdepth = %d  ,  parentID= %d \n", curdepth , parentID);

        }
          call Seed.init(TOS_NODE_ID);
     
    }
   
    event void RadioControl.startDone(error_t err)
    {
        if (err == SUCCESS)
        {
            dbg("Radio" , "Radio initialized successfully!!!\n");
                 //children initialisation
                        InitchildArr();
            //start  sending messages after routing
            call SendMsgTimer.startOneShot(3000);
                 //timer to count the rounds
                        call periodTimer.startPeriodicAt((-10000),TIMER_PERIOD_MILLI);
           
            if (TOS_NODE_ID==0)
            {    //timer to start sending routingMsg
                call RoutingMsgTimer.startOneShot(TIMER_FAST_PERIOD);
            }
        }
        else
        {    //if not working
            dbg("Radio" , "Radio initialization failed! Retrying...\n");

            call RadioControl.start();
        }
    }
   
    event void RadioControl.stopDone(error_t err)
    {
        dbg("Radio", "Radio stopped!\n");

    }
   
   
    event void RoutingMsgTimer.fired()
    {       routingwith2func * r2f;
                routingwith1func * r1f;

        message_t tmp;
        error_t enqueueDone;
        uint8_t j;
        RoutingMsg* mrpkt;
        dbg("SRTreeC", "RoutingMsgTimer fired!");
                roundCounter+=1;
        //for round1
        if (TOS_NODE_ID==0)
        {
                   
        //max or count(c=0) or max&count(c=1)  
                
                 uint8_t c;
               
                 c=((call randomN.rand16())%2);
               
                if(c+1==2){
                    dbg("Tina","we have max&count\n");  
                          } else{
                   dbg("Tina","we have max or count\n");
                   }
                  for(j=0;j<c+1;j++){
                      //choice of count or max
                       choice[j]=((call randomN.rand16())%2)+1;
                                  
                     //if we have two queries  must be differents              
                 while(choice[0]==choice[1]){
                 
                    choice[0]=((call randomN.rand16())%2)+1;
                            }
               
                       

                        }
         
        tct=((call randomN.rand16())%20);
                  while((tct %5)!=0){
                  //random tct
                  tct=((call randomN.rand16())%20);  
        }
               dbg("Tina","tct is:%d\n",tct);  
        }
       
        if(call RoutingSendQueue.full())
        {
                 dbg("SRTreeC","RoutingSendQueue is full \n");

            return;
        }
         
        //if we have tina with max&count
                 if(choice[1]!=0){
                  // get payload for routingwith2func
                  r2f=(routingwith2func *)(call RoutingPacket.getPayload(&tmp, sizeof(routingwith2func)));

                  if(r2f==NULL)
        {
            dbg("SRTreeC","RoutingMsgTimer.fired(): No valid payload... \n");

            return;
        }     //assign values
               atomic{
              ((routingwith2func *) r2f)->depth=curdepth;  
               ((routingwith2func *) r2f)->choice0=choice[0];
               ((routingwith2func *) r2f)->choice1=choice[1];
               ((routingwith2func *) r2f)->tct=tct;
       
              }
        }
             //else Simple tina
               else{
              // get payload for routingwith1func
               r1f=(routingwith1func *)(call RoutingPacket.getPayload(&tmp, sizeof(routingwith1func)));

                  if(r1f==NULL)
        {
            dbg("SRTreeC","RoutingMsgTimer.fired(): No valid payload... \n");

            return;
        }  //assign value
               atomic{
               ((routingwith1func *)r1f)->depth=curdepth;  
               ((routingwith1func *)r1f)->choice0=choice[0];
                 
       
                 choice[1]=0;
                
                ((routingwith1func *) r1f)->tct=tct;
             
       
              }


                      }
       
       
        dbg("SRTreeC" , "Sending RoutingMsg... \n");

   
       
       //Enqueue
        enqueueDone=call RoutingSendQueue.enqueue(tmp);
       
        if( enqueueDone==SUCCESS)
        {
            if (call RoutingSendQueue.size()==1)
            {
                dbg("SRTreeC", "SendTask() posted!!\n");

                post sendRoutingTask();
            }
           
            dbg("SRTreeC","RoutingMsg enqueued successfully in SendingQueue!!!\n");

        }
        else
        {
            dbg("SRTreeC","RoutingMsg failed to be enqueued in SendingQueue!!!");

        }      
    }
      event void SendMsgTimer.fired(){
         message_t t;
         error_t enqueueDone;
         Onemessage *mpkg; 
          
         
       //when finish routing
        if(!finishedRouting){
       dbg("RoutingMSG","Rooting Finished");
        
       finishedRouting=TRUE;
        //start sending measurments every epoch
        
       call SendMsgTimer.startPeriodicAt(((-(10000)-((curdepth+1)*TIMER_FAST_PERIOD))+(TOS_NODE_ID*2)),TIMER_PERIOD_MILLI);
       
                            }else
                            {
                         dbg("Measurments","NODE_ID=%d, curdepth=%d\n",TOS_NODE_ID,curdepth);
                         //if node=0 ,print  final result
                         if(TOS_NODE_ID!=0){
                         
                           dbg("Measurments","Starting data transmition to parent!\n");
                         
                                             }
                         if(roundCounter==1){
                          //random measurment 0..80
                          measurment=(call randomN.rand16())%80;
                          //take the previous measurments
                          prev_measurment=measurment;
                          }else{
                         measurment=0;
                          
      //while the measurment is bigger or less than  the previous+10%*previous do it again until find one that not cross the limits.
   while( measurment>prev_measurment+((float) 10/100) *prev_measurment ||measurment<prev_measurment-((float) 10/100) *prev_measurment){
                         measurment=(call randomN.rand16())%80;
                          
                       }
                        prev_measurment=measurment;


                
                       }
                        
 
                        dbg("Measurments","measurment is:%d\n",measurment);
                    if (call MessSendQueue.full())
        {
            dbg("SRTreeC","MessSendQueue is full!\n");

            return;
        }       // cresate a message that holding the measurment
                call MessAMPacket.setDestination(&t,parentID);
                mpkg=(Onemessage*) (call MessPacket.getPayload(&t,sizeof(Onemessage)));
                call MessPacket.setPayloadLength(&t,sizeof(Onemessage));
                if(mpkg==NULL)
                 {
                 dbg("SRTreeC","no valid payload...");
                 return;

                  }
                  mpkg->m=measurment;
                enqueueDone=call MessSendQueue.enqueue(t);
                if( enqueueDone== SUCCESS)
        {

            if(call MessSendQueue.size()==1){
                          //post send task
                          post sendMessTask();
                         
                                                     }

           
                    dbg("SRTreeC","Msg enqueue successfully!!!1 \n");
        }
        else
        {
            dbg("SRTreeC","Msg enqueue failed!!! \n");
   
        }
               


                             }
     

                                      }
   
       event void periodTimer.fired(){
         roundCounter++;
         
      if(TOS_NODE_ID==0){
      
      dbg("Measurments","############ROUND  %u ########\n",roundCounter);
}
                              }
   
    event void RoutingAMSend.sendDone(message_t * msg , error_t err)
    {
       
       
        dbg("SRTreeC" , "Package sent %s \n", (err==SUCCESS)?"True":"False");

       
       
        if(!(call RoutingSendQueue.empty()))
        {
            post sendRoutingTask();
        }
       
   
       
    }
       event void counterTimer.fired(){
      
      
       
        
 }
   
    event void MessAMSend.sendDone(message_t *msg , error_t err)
    {
       
       
   
 dbg("SRTreeC" , "Package sent %s \n", (err==SUCCESS)?"True":"False");

       
        if(!(call MessSendQueue.empty()))
        {
            post sendMessTask();
        }
       
       
       
    }
   

   
   
    event message_t* MessReceive.receive( message_t* msg , void* payload , uint8_t len)
    {
        error_t enqueueDone;
        message_t tmp;
        uint16_t msource;
       //find massage source
        msource = call MessAMPacket.source(msg);
       
        dbg("SRTreeC", "### MessReceive.receive() start ##### \n");
       


       //save message on a temp var
        atomic{
        memcpy(&tmp,msg,sizeof(message_t));
       
        }
        enqueueDone=call MessReceiveQueue.enqueue(tmp);
       
        if( enqueueDone== SUCCESS)
        {
          //post receive task
            post receiveMessTask();
        }
        else
        {
            dbg("SRTreeC","Msg enqueue failed!!! \n");
   
        }
       
       
        dbg("SRTreeC", "### MessReceive.receive() end ##### \n");
        return msg;
    }
        event message_t* RoutingReceive.receive( message_t * msg , void * payload, uint8_t len)
    {
        error_t enqueueDone;
        message_t tmp;
        uint16_t msource;
       
        msource =call RoutingAMPacket.source(msg);
       
        dbg("SRTreeC", "### RoutingReceive.receive() start ##### \n");
        dbg("SRTreeC", "Something received!!!  from %u  %u \n",((RoutingMsg*) payload)->senderID ,  msource);
       
       
        atomic{
        memcpy(&tmp,msg,sizeof(message_t));
       
        }
        enqueueDone=call RoutingReceiveQueue.enqueue(tmp);
        if(enqueueDone == SUCCESS)
        {

            post receiveRoutingTask();
        }
        else
        {
            dbg("SRTreeC","RoutingMsg enqueue failed!!! \n");
       
        }
       
       
       
        dbg("SRTreeC", "### RoutingReceive.receive() end ##### \n");
        return msg;
    }
   
   
   
    ////////////// Tasks implementations //////////////////////////////
   
   
    task void sendRoutingTask()
    {
       
        error_t sendDone;
       
       

        if (call RoutingSendQueue.empty())
        {
            dbg("SRTreeC","sendRoutingTask(): Q is empty!\n");

            return;
        }
       
       
       
       
        radioRoutingSendPkt = call RoutingSendQueue.dequeue();
      
        if(choice[1]!=0)
                  { 
                  //send routing message if it is TINA with max&count
                   sendDone=call RoutingAMSend.send(AM_BROADCAST_ADDR,&radioRoutingSendPkt,sizeof(routingwith2func));
               
                    }else{
                      //send routing message if it is  simpleTINA
                    sendDone=call RoutingAMSend.send(AM_BROADCAST_ADDR,&radioRoutingSendPkt,sizeof(routingwith1func));

                          }
       
       
        if ( sendDone== SUCCESS)
        {
            dbg("SRTreeC","sendRoutingTask(): Send returned success!!!\n");

           
        }
        else
        {
            dbg("SRTreeC","send failed!!!\n");

        }
    }
    /**
     * dequeues a message and sends it
     */
    task void sendMessTask()
    {
        uint8_t mlen,nodeS;//, skip;
        error_t sendDone;
        uint16_t mdest;
         bool pass=FALSE;
         Onemessage *mpayload;
                message_t tmp;
       
       
       

        if (call MessSendQueue.empty())
        {
            dbg("SRTreeC","sendMessTask(): Q is empty!\n");

            return;
        }
       
       
       //deqeue message
        radioMessSendPkt = call MessSendQueue.dequeue();
       
       //find the payload length
        mlen=call MessPacket.payloadLength(&radioMessSendPkt);
       
        mpayload= call MessPacket.getPayload(&radioMessSendPkt,mlen);
       
        if(mlen!= sizeof(Onemessage))
        {
            dbg("SRTreeC", "\t\t sendMessTask(): Unknown message!!\n");
        return;
        }         //save measurment
                 nodeS=mpayload->m;
        //NORMAL TINA
       
        if(choice[1]==0){
              
                 uint8_t f;
                 Onemessage *mess1;
                 //send message to Onemessage struct
                 call MessPacket.setPayloadLength(&tmp,sizeof(Onemessage));
                
                 mess1=(Onemessage*)(call MessPacket.getPayload(&tmp,sizeof(Onemessage)));
                 if(mess1==NULL){
                   dbg("SRTreeC","SendMsgTimer.fired():No valid payload...\n");
                   return;

                     }
                  if(choice[0]==MAX)
                  { //calculate max function
                    f=calculateF(MAX,nodeS);

                   if(TOS_NODE_ID ==0){
                    dbg("Measurments","Final result of MAX function:%d\n",f);
                   }
                   }
                   if(choice[0]==COUNT)
                    
                    {
                   // calculate count function
                    f=calculateF(COUNT,nodeS);
                   if(TOS_NODE_ID ==0){
                    dbg("Measurments","Final result of count function:%d\n",f);
                    }
                    }
                    if(TOS_NODE_ID!=0)
                     {
               //if the result is outside the tct or we are in the first round
                     if(roundCounter==1|| f>previousCalc+((float) tct/100) *previousCalc ||f<previousCalc-((float) tct/100) *previousCalc)
            {       pass=TRUE;
              dbg("Tina","measurments pass the tct!New measurment:%d\n",f);
             //prepare message
              atomic
              {
         
               previousCalc=f;
               call MessAMPacket.setDestination(&tmp,parentID);
               ((Onemessage*)mess1)->m=f;
               }
             
             }else{
                  dbg("Tina","measurments  dont pass the tct!old measurment:%d\n",previousCalc);
                 ((Onemessage*)mess1)->m=previousCalc;
                   }                  


                      }
                 
                 // Tina with max&count  
                   }else{
                     uint8_t f[2],mes[2],cf;
                    Twomess* mess2;
                     cf=0;
                  //send message to Twomess struct
                 call MessPacket.setPayloadLength(&tmp,sizeof(Twomess));
             
                 mess2=(Twomess*)(call MessPacket.getPayload(&tmp,sizeof(Twomess)));
                 if(mess2==NULL){
                   dbg("SRTreeC","SendMsgTimer.fired():No valid payload...\n");
                   return;

                                }
                   if(choice[0]==MAX||choice[1]==MAX){
           
                    f[0]=calculateF(MAX,nodeS);
                    mes[0]=MAX;
                 
                 
                 
                if(TOS_NODE_ID ==0){
                    dbg("Measurments","Final result of max function:%d\n",f[0]);
                 

                    }
                   

                    }
                    if(choice[0]==COUNT||choice[1]==COUNT)
                    {
                    
                    f[1]=calculateF(COUNT,nodeS);
                   
                    mes[1]=COUNT;
                 
                 
                 
                    if(TOS_NODE_ID ==0){
                    dbg("Measurments","Final result of count function:%d\n",f[1]);
                 

                    }
                   
                     
               
                       }
                if(TOS_NODE_ID!=0) {
               //if the result is outside the tct or we are in the first round
               if(roundCounter==1|| f[0]>previousCalc+((float) tct/100) *previousCalc ||f[0]<previousCalc-((float) tct/100) *previousCalc)
            {      pass=TRUE;
              dbg("Tina"," max function:measurments pass the tct!New measurment:%d prev:%d\n",f[0],previousCalc);
              atomic
              {
         
                 previousCalc=f[0];//max
               call MessAMPacket.setDestination(&tmp,parentID);
               ((Twomess*)mess2)->m1=f[0];
               ((Twomess*)mess2)->measurmentsfield[0]=mes[0];
                }
             
             }else{
                  dbg("Tina","max function:measurments  dont pass the tct!old measurment:%d\n",previousCalc);
                 ((Twomess*)mess2)->m1=previousCalc;
               ((Twomess*)mess2)->measurmentsfield[0]=mes[0];
                 
                   }
              if(roundCounter==1|| f[1]>previousCalc1+((float) tct/100) *previousCalc1 ||f[1]<previousCalc1-((float) tct/100) *previousCalc1){
                  pass=TRUE;
                dbg("Tina"," count function:measurments pass the tct!New measurment:%d,prev:%d\n",f[1],previousCalc1);
              atomic
              {
               

               previousCalc1=f[1];//count
               call MessAMPacket.setDestination(&tmp,parentID);
                ((Twomess*)mess2)->m2=f[1];
                ((Twomess*)mess2)->measurmentsfield[1]=mes[1];
               }
             
             }else{
                  dbg("Tina","count function:measurments  dont pass the tct!old measurment:%d\n",previousCalc1);
                  ((Twomess*)mess2)->m2=previousCalc1;
                ((Twomess*)mess2)->measurmentsfield[1]=mes[1];
                 }
                  }
                  }
          //pass tina 
           if(TOS_NODE_ID!=0&& pass==TRUE) 
            {
            atomic{ 
           // copy  message to radioMessSendPkt
            memcpy(&radioMessSendPkt,&tmp,sizeof(message_t));
             }
           //set  destination
           mdest=call MessAMPacket.destination(&radioMessSendPkt);
           mlen=call MessPacket.payloadLength(&radioMessSendPkt);
           sendDone=call MessAMSend.send(mdest,&radioMessSendPkt,mlen);
          if ( sendDone== SUCCESS){dbg("SRTreeC","sendMessTask(): Send returned success!!!\n");

        }
        //
        else
        {
            dbg("SRTreeC","send failed!!!\n");

           }}else if(TOS_NODE_ID!=0&& pass==FALSE){ dbg("Tina","dont send because of tct\n");}}


    ////////////////////////////////////////////////////////////////////
    //*****************************************************************/
    ///////////////////////////////////////////////////////////////////
    /**
     * dequeues a message and processes it
     */
   
    task void receiveRoutingTask()
    {
        uint16_t m;
        uint8_t len;
        message_t radioRoutingRecPkt;
       
                //dequeue message
        radioRoutingRecPkt= call RoutingReceiveQueue.dequeue();
       
        len= call RoutingPacket.payloadLength(&radioRoutingRecPkt);
       
        dbg("SRTreeC","ReceiveRoutingTask(): len=%u \n",len);

        // processing of radioRecPkt
        m=call RoutingAMPacket.source(&radioRoutingRecPkt);
        // pos tha xexorizo ta 2 diaforetika minimata???
               
        if(len == sizeof(routingwith2func)||len == sizeof(routingwith1func))
        {
       
                       //Node without parent
             
            if ((parentID<0)||(parentID>=65535))
            {    //tina with 2 fields
                  if(len == sizeof(routingwith2func)){
                             
             routingwith2func * r2f;
                      r2f=(routingwith2func*) (call RoutingPacket.getPayload(&radioRoutingRecPkt,len));  
                       parentID=m;
                       curdepth=r2f->depth+1;
                       choice[0]=r2f->choice0;
                       
                       choice[1]=r2f->choice1;
                       
                       tct=r2f->tct;
            dbg("SRTreeC","Now the node %d have a perent with parentID %d and currentdepth %d",TOS_NODE_ID,parentID,curdepth);  
           
                }
                        else{
                        routingwith1func *r1f;
                      r1f=(routingwith1func*) (call RoutingPacket.getPayload(&radioRoutingRecPkt,len));  
                       parentID=m;
                       curdepth=r1f->depth+1;
                       choice[0]=r1f->choice0;
                     
                       choice[1]=0;
                       tct=r1f->tct;
            dbg("SRTreeC","Now the node %d have a parent with parentID %d and currentdepth %d",TOS_NODE_ID,parentID,curdepth);  
                         
                     
 
                  }
                call RoutingMsgTimer.startOneShot(TIMER_FAST_PERIOD);            
        }
             else
               {
          dbg("SRTreeC","the node %d has already parent with parentID %d and curdepth %d",TOS_NODE_ID,parentID,curdepth);
     
                 }
}
       
        else
        {
            dbg("SRTreeC","receiveRoutingTask():Empty message!!! \n");

            return;
        }
       
    }


////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////  
   
     
    task void receiveMessTask()
    {
        message_t tmp;
        uint8_t len,j;
        uint16_t m;
        message_t radioMessRecPkt;
        Onemessage* m1;
        Twomess* ms2;
       
       //dequeue message
        radioMessRecPkt= call MessReceiveQueue.dequeue();
       //find payload length
        len= call MessPacket.payloadLength(&radioMessRecPkt);
         //source
        m= call MessAMPacket.source(&radioMessRecPkt); 
       
        dbg("SRTreeC","receiveMessTask(): len=%u \n",len);
        //normal tina 
       if(choice[1]==0) {
        m1=(Onemessage*) (call MessPacket.getPayload(&radioMessRecPkt,len)); 
        for(j=0;j<MAX_Ch;j++)
        { 
        if(Children[j].ChID==0||Children[j].ChID==m){
         //new child put it in the table
         if(Children[j].ChID==0)
              {
             Children[j].ChID=m;
            dbg("SRTreeC","New child");
              }
        if(choice[0]==MAX)
         {
           Children[j].max=((Onemessage*)m1)->m;
           dbg("Measurements","Received from Child :%d max:%d",Children[j].ChID,Children[j].max);
           
                         }
         else{
           Children[j].count=((Onemessage*)m1)->m;
           dbg("Measurements","Received from Child :%d count:%d",Children[j].ChID,Children[j].count);
              }
             break;
                         }
}
       
    } 
//tina with max and count
     else{
     uint8_t mf[2];
      ms2=(Twomess*)(call MessPacket.getPayload(&radioMessRecPkt,len));
      mf[0]=((Twomess*)ms2)->measurmentsfield[0];
      mf[1]=((Twomess*)ms2)->measurmentsfield[1];
        for(j=0;j<MAX_Ch;j++)
        {
        if(Children[j].ChID==0||Children[j].ChID==m){
         //new child put it in th table
         if(Children[j].ChID==0)
              {
             Children[j].ChID=m;
            dbg("SRTreeC","New child\n");
              }
        if(mf[0]==MAX)
         {
           Children[j].max=((Twomess*) ms2)->m1;
           dbg("SRTreeC","Received from Child :%d max:%d\n",Children[j].ChID,Children[j].max);
           
                         }
         else{
           Children[j].count=((Twomess*) ms2)->m2;
           dbg("SRTreeC","Received from Child :%d count:%d\n",Children[j].ChID,Children[j].count);
              }

       if(mf[1]==MAX)
         {
           Children[j].max=((Twomess*) ms2)->m1;
           dbg("SRTreeC","Received from Child :%d max:%d\n",Children[j].ChID,Children[j].max);
           
                         }
         else{ 
          
           Children[j].count=((Twomess*) ms2)->m2;
           dbg("SRTreeC","Received from Child :%d count:%d\n",Children[j].ChID,Children[j].count);
              }
          break;
        }
                         }
    }
    dbg("SRTreeC","message receined from %d\n",m);

   }

uint8_t calculateF(uint8_t operation,uint8_t m){
uint8_t result,j;

switch(operation)
{
case MAX:
result=m;
for(j=0;j<MAX_Ch && Children[j].ChID!=0;j++){
dbg("calculations","child %d has max %d\n", Children[j].ChID,Children[j].max);
result=(result>Children[j].max)? result:Children[j].max;
}
dbg("calculations","the max is %d\n",result);
break;
case COUNT:
result=1;
for(j=0;j<MAX_Ch && Children[j].ChID!=0;j++){
dbg("calculations","child %d has count %d\n", Children[j].ChID,Children[j].count);
result +=Children[j].count;
}
dbg("calculations","the count is %d\n",result);
break;
default:
return 0;
}
return result;
}
}
