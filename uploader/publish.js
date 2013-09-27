module.exports = publish;

function publish(f, cb) {
	console.log('publishing', f);

	setTimeout(cb, 1000);
}