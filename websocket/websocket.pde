// http://tools.ietf.org/html/draft-ietf-hybi-thewebsocketprotocol-03
// http://jwebsocket.googlecode.com/svn-history/r906/trunk/shared/J2ME/jWebSocketJavaMEClient/org/jwebsocket/kit/WebSocketHandshake.j
// http://code.google.com/p/processing/wiki/LibraryBasics


import processing.net.*;
import  java.security.MessageDigest;
import java.math.*;

Server myServer;
Client myClient;

int val = 0;



void setup() {
  size(200, 200);

  // Starts a myServer on port 5204
  myServer = new Server(this, 1234); 


}



byte[] procClientHeader(String header) {
  String[] data = split( header, '\n');

  long longnum1 = -1;
  long longnum2 = -1;
  BigInteger sec1 = null;
  BigInteger sec2= null;

  byte[] SecKey3 = new byte[8];
  byte[] lSecKeyResp = new byte[8];

  /*
  get the two Sec keys and return them as longs
   */
  for ( int i=0; i < data.length; i++) {
    if ( data[i].indexOf("Sec-WebSocket-Key1:") != -1) { 
      sec1  = procValue( data[i] ); 
      //println("l1:" + sec1); 
    } 
    if ( data[i].indexOf("Sec-WebSocket-Key2:") != -1) { 
      sec2 =  procValue( data[i] );  
      //println("l2:" + sec2);
    }
  }

  /*
  get the random 8 bits at the end as a string
   */
  SecKey3 = data[data.length-1].getBytes();
  //println("sec3:" + SecKey3);

  // concatene 3 parts secNum1 + secNum2 + secKey
  byte[] l128Bit = new byte[16];
  byte[] lTmp;
  lTmp = sec1.toByteArray();
  for (int i = 0; i < 4; i++) {
    l128Bit[i] = lTmp[i];
  }
  lTmp = sec2.toByteArray();
  for (int i = 0; i < 4; i++) {
    l128Bit[i + 4] = lTmp[i];
  }
  lTmp = SecKey3;
  for (int i = 0; i < 8; i++) {
    l128Bit[i + 8] = lTmp[i];
  }


  //println("Concatted stuff:" + l128Bit );
  //println("length:" + l128Bit.length);
  MessageDigest m = null;
  try {
    m = java.security.MessageDigest.getInstance("MD5");
    //m.reset();
    lSecKeyResp = m.digest( l128Bit)  ;

  } 
  catch (Exception e) { 
  }

  //println("md5sum:" + lSecKeyResp);
  
  return lSecKeyResp;


}


BigInteger procValue(String Value) {

  Value = Value.substring(20);
  Value = Value.trim();

  String number = "";
  int count =0;
  BigInteger  returnLong = new BigInteger("0") ;

  CharacterIterator it = new StringCharacterIterator(Value);

  for (char ch=it.first(); ch != CharacterIterator.DONE; ch=it.next()) {
    if ( Character.isDigit(ch) ) {
      number = number + ch;
    } 

    if ( ch == ' ') {
      count++;
    }
  } 

  //println("Number:" + number);
  long l =  Long.parseLong( number ) / count ;

  return BigInteger.valueOf(l);

}


String getOrigin(String header) {
  String[] data = split( header, '\n');
  for (int i=0; i < data.length; i++) {
     if (data[i].indexOf("Origin") != -1 ) {
       return data[i].substring(8).trim();
     }
  }
  return null;
}

String getHost(String header) {
  String[] data = split( header, '\n');
  for (int i=0; i < data.length; i++) {
     if (data[i].indexOf("Host") != -1 ) {
       return data[i].substring(5).trim();
     }
  }
  return null;
}

void updateServer() {
  
 Client thisClient = myServer.available();
 if (thisClient == null) { return;}
 
 println("Connecting:");
  
 String whatClientSaid = thisClient.readString();

 // Make sure we get the entire message
 while (whatClientSaid == null) {
   whatClientSaid = thisClient.readString();
 }
 
 while ( thisClient.available() > 0 ) {
    whatClientSaid = whatClientSaid + thisClient.readString();   
 }
println( whatClientSaid);
  // if this is the inital, then setup the connection

   if (whatClientSaid.indexOf("Sec-WebSocket") > 0)  {
    try {
      
      String origin = getOrigin(whatClientSaid);
      String host = getHost(whatClientSaid);
      
      String myResponse =  
        "HTTP/1.1 101 WebSocket Protocol Handshake\r\n"
        + "Upgrade: WebSocket\r\n"
        + "Connection: Upgrade\r\n"
        + "Sec-WebSocket-Origin:" + origin + "\r\n"
        + "Sec-WebSocket-Location: ws://" + host + "/\r\n"  
        + "\r\n" + new String(procClientHeader( whatClientSaid) )  ;


      //println( myResponse );
      thisClient.write  ( myResponse );

      thisClient.write(0x00);

      thisClient.write("some data");

      thisClient.write(0xff);

    } 
    catch(Exception e) { 
    }
   } else {
     // else this is data streaming in from the client
      println( whatClientSaid); 
   }
   
   
   
   
}   


void draw() {
 updateServer();
 
}





