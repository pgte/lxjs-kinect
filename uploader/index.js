var fs      = require('fs');
var watch   = require('watch');
var async   = require('async')
var publish = require('./publish');

var queue = async.queue(publishAndRemove, 1);
queue.drain = onDrain;
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

	function published(err) {
		if (err) {
			throw err;
			setTimeout(function() {
				queue.push(f);
			}, 10000);

			return cb();
		}
		fs.unlink(f, unlinked);
	}

	function unlinked(err) {
		if (!err) console.log('removed', f)
		cb(err);
	}
}

function onDrain() {
	console.log('all done for now');
}

console.log('uploader starting');

process.once('uncaughtException', function(err) {
  console.error(err);
  process.exit(1);
});

process.on('SIGINT', function() {
	console.error('interrupted');
	process.exit(0);
});