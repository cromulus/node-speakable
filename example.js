var Speakable = require('./');


// Setup google speech
var speakable = new Speakable({
  key: 'KEY'
});

speakable.on('speechStart', function() {
  console.log('onSpeechStart');
});

speakable.on('speechStop', function() {
  console.log('onSpeechStop');
  speakable.recordVoice();
});

speakable.on('speechReady', function() {
  console.log('onSpeechReady');
});

speakable.on('error', function(err) {
  console.log('onError:');
  console.log(err);
  speakable.recordVoice();
});

speakable.on('speechResult', function(spokenWords) {
  console.log('onSpeechResult:');
  console.log(spokenWords);
  var querystring = require('querystring');
  var http = require('http');

  var data = querystring.stringify({
    words: spokenWords,
  });

  var options = {
    host: 'my.url',
    port: 80,
    path: '/words',
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Content-Length': Buffer.byteLength(data)
    }
  };

  var req = http.request(options, function(res) {
    res.setEncoding('utf8');
    res.on('data', function(chunk) {
      console.log("body: " + chunk);
    });
  });

  req.write(data);
  req.end();
});

speakable.recordVoice();