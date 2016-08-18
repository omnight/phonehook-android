package com.omnight.phonehook;

//import com.mindtherobot.samples.tweetservice.TweetSearchResult;
//import com.mindtherobot.samples.tweetservice.TweetCollectorListener;

interface PhonehookDaemonInterface {

  void testLookup(int botId, String nr);
  boolean ping();


  //void addListener(TweetCollectorListener listener);
  //void removeListener(TweetCollectorListener listener);
}
