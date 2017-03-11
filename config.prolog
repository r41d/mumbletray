% mumbletray configuration

% Channel Viewer Protocol JSON URL
cvpURL("http://mumble.XXX.org/mumble/1.json").

% Configure all usernames that belong to "me"
myself("me on tower").
myself("me on laptop").
myself("me on smartphone").

% Users in access-restricted channels and all subchannels of them will be ignored.
% It also makes sense to add afk channels here, because these aren't intended for actually communicating.
restricted("afk").
restricted("private").
