<?php
// Edit the four values below

if (getenv("HTTPS_PROXY") !== false) {
	$PROXY_URL = str_replace("http://", "", $_ENV['HTTPS_PROXY']); // Proxy server address
	$stream_default_opts = array(
		'http' => array(
			'proxy' => "tcp://$PROXY_URL",
			'request_fulluri' => true,
		)
	);
	stream_context_set_default($stream_default_opts);
	error_log( "$PROXY_URL has been set to: " . $PROXY_URL . " ", 0);
} else {
	$stream_default_opts = array(
		'http' => array(
			'proxy' => "tcp://proxy:3128",
			'request_fulluri' => true,
		)
	);
	stream_context_set_default($stream_default_opts);
}
