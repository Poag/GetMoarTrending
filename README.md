# GetMoarTrending
A bash script to collect Trending tags from mastodon instances, database those tags and then generate a config.json for GetMoreFediverse to use to import those trending tags. By default imports tags seen in the last 7 days.

Requires sqlite for the db.

Update INSERT_RELAY_URL_HERE and INSERT_API_KEY_HERE with your relay and api key.

Use the produced config with [GetMoarFediverse](https://github.com/g3rv4/GetMoarFediverse/) to import content into your instance.
