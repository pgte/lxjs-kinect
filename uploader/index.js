var fs      = require('fs');
var watch   = require('watch');
var async   = require('async')
var publish = require('./publish');

var queue = async.queue(publishAndRemove, 1);
var processing = [];

watch.createMonitor(__dirname + '/../photobooth', function(monitor) {
	Object.keys(monitor.files).forEach(onCreated);
	monitor.on('created', onCreated);
});

function onCreated(f) {
	if (! f.match(/\.png$/)) return;
	if (processing.indexOf(f) > -1) return;
	processing.push(f);
	console.log('created %j', f);
  setTimeout(function() {
  	queue.push(f);
  }, 2000);
}

function publishAndRemove(f, cb) {
	publish(f, published);

	function published() {
		fs.unlink(f, unlinked);
	}

	function unlinked(err) {
		if (err) console.error(err);
		else console.log('removed', f)
		cb();
	}
}