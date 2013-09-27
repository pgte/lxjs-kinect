var assert = require('assert');
var config = require('./config.json');
assert(config.user, 'need user in credentials');
assert(config.pass, 'need pass in credentials');
assert(config.stream, 'need stream in credentials');

var Cloudup = require('cloudup-client');
module.exports = publish;

var cloudup = Cloudup({
	user: config.user,
	pass: config.pass
});

function publish(f, cb) {
	console.log('publishing', f);

	var timeout = setTimeout(function() {
		console.error('timeout');
		cb(new Error('uploading ' + f + ' timed out'));
	}, config.timeout_ms);

	var s = cloudup.stream(config.stream);
	s.on('error', onError);
	s.file(f);
	s.save(saved);

	function saved(err) {
		clearTimeout(timeout);
		callback(err);
	}

	function onError(err) {
		console.error(err);
		callback(err);
	}

	var calledback = false;
	function callback() {
		if (! calledback) {
			calledback = true;
			cb.apply(null, arguments);
		}
	}
}