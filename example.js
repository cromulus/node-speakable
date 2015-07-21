var Speakable = require('./');
var requestify = require('requestify');


// Setup google speech
var speakable = new Speakable({
  key: 'KEY',
  threshold: 0.4
});

speakable.on('speechStart', function() {
  console.log('speech start');
});

speakable.on('speechStop', function() {
  console.log('speech stop');
  speakable.recordVoice();
});

speakable.on('speechReady', function() {
  console.log('speechready');
});

speakable.on('error', function(err) {
  console.log('onError:');
  console.log(err);
  speakable.recordVoice();
});

speakable.on('speechResult', function(spokenWords) {


  var my_words = JSON.stringify(spokenWords);
  console.log(my_words);

  requestify.post('http://127.0.0.1:4567/words', {
    words: spokenWords
  }).then(function(response) {
    console.log(response.getBody());
  });
});
speakable.recordVoice();