API_Key <- ""; //Type your Xively API Key
Feed_ID <- "" //Type your Feed ID
BatteryVolts <- "BatteryVolts"; //Type your Channel ID
Temp <- "Temp"; //Type your Channel ID for Temp

Xively <- {}; // this makes a 'namespace'

class Xively.Client {
  ApiKey = null;
  triggers = [];
  
constructor(apiKey) {
    this.ApiKey = apiKey;
    }
  
  /*****************************************
  * method: PUT
  * IN:
  * feed: a XivelyFeed we are pushing to
  * ApiKey: Your Xively API Key
  * OUT:
  * HttpResponse object from Xively
  * 200 and no body is success
  *****************************************/
  function Put(feed){
    local url = "https://api.xively.com/v2/feeds/" + feed.FeedID + ".json";
    local headers = { "X-ApiKey" : ApiKey, "Content-Type":"application/json", "User-Agent" : "Xively-Imp-Lib/1.0" };
    local request = http.put(url, headers, feed.ToJson());
    
    return request.sendsync();
    }
  
  /*****************************************
  * method: GET
  * IN:
  * feed: a XivelyFeed we fulling from
  * ApiKey: Your Xively API Key
  * OUT:
  * An updated XivelyFeed object on success
  * null on failure
  *****************************************/
  function Get(feed){
    local url = "https://api.xively.com/v2/feeds/" + feed.FeedID + ".json";
    local headers = { "X-ApiKey" : ApiKey, "User-Agent" : "xively-Imp-Lib/1.0" };
    local request = http.get(url, headers);
    local response = request.sendsync();
    if(response.statuscode != 200) {
    server.log("error sending message: " + response.body);
    return null;
    }
  
  local channel = http.jsondecode(response.body);
  for (local i = 0; i < channel.datastreams.len(); i++)
    {
    for (local j = 0; j < feed.Channels.len(); j++)
      {
      if (channel.datastreams[i].id == feed.Channels[j].id)
        {
        feed.Channels[j].current_value = channel.datastreams[i].current_value;
        break;
        }
      }
    }
  
  return feed;
  }
  
}


class Xively.Feed{
  FeedID = null;
  Channels = null;
  
  constructor(feedID, channels)
  {
    this.FeedID = feedID;
    this.Channels = channels;
  }
  
  function GetFeedID() { return FeedID; }
  
  function ToJson()
    {
      local json = "{ \"datastreams\": [";
      for (local i = 0; i < this.Channels.len(); i++)
    {
      json += this.Channels[i].ToJson();
      if (i < this.Channels.len() - 1) json += ",";
    }
      json += "] }";
      return json;
    }
  }

class Xively.Channel {
  id = null;
  current_value = null;
  
  constructor(_id)
  {
    this.id = _id;
  }
  
  function Set(value) {
  this.current_value = value;
  }
  
  function Get() {
  return this.current_value;
  }
  
  function ToJson() {
    local json = http.jsonencode({id = this.id, current_value = this.current_value });
    server.log(json);
    return json;
    }
}
temp <- 0;
device.on ("temp", function(v) {
  temp = v;
});

client <- Xively.Client(API_Key);
device.on("Batt", function(v) {
  channel1 <- Xively.Channel(BatteryVolts);
  channel1.Set(v);
  channel2 <- Xively.Channel(Temp);
  channel2.Set(temp);
  feed1 <- Xively.Feed(Feed_ID, [channel1, channel2]);
  client.Put(feed1);
});