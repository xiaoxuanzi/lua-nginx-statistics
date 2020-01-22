Name
====

lua-nginx-statistics - Provides statistics for each upstream server in nginx.

Table of Contents
=================

* [Name](#name)
* [Status](#status)
* [Synopsis](#synopsis)
* [Description](#description)
* [Methods](#methods)
* [Installation](#installation)
* [Author](#author)
* [Copyright and License](#copyright-and-license)
* [See Also](#see-also)

Status
======

This library  is already production ready.

Synopsis
========

```nginx
http {

    lua_shared_dict statistics_dict 10M;
    lua_package_path "/path/to/lua-nginx-statistics/?.lua;;";
    log_by_lua_file "/path/to/lua-nginx-statistics/statistics.lua";

    upstream backend{
        server 0.0.0.0:2020;
    }

    server {
        listen       2019;
        location /test {
			proxy_pass http://backend;
        }

        location /statistics {
			default_type 'application/json';
			content_by_lua_file "/path/to/lua-nginx-statistics/statistics_output.lua";
			access_log off;
		}

    }

    server {
        listen       2020;
        location /test {
            default_type 'text/html';
            content_by_lua_block{
				ngx.sleep(1)
                ngx.say('hello 2020')
            }
        }
    }
}

```

Description
===========

This library provides statistics for each backend server in nginx upstreams.

The default prefix is $proxy_host, you can set anyone you like in location,
if you change it and remember to adjust code in statistics.lua
[Back to TOC](#table-of-contents)

Get statistics
-------------
**syntax:** `statistics.get_statistics()`

**context:** *any*

Get nginx statistics with json format.
Via "http://127.0.0.1:2019/statistics"
One typical output is:
```
{
	backend: {
		err_count: 1,
		upstream_count: 11,
		upstream_response_time: 9.037,
		request_time: 9.451,
		err_count|499: 1,
		request_count: 9
	}
}

```

Installation
============
You need to configure the lua_package_path directive to add the path of your lua-nginx-statistics source tree to ngx_lua's Lua module search path, as in 
```
    lua_shared_dict statistics_dict 10M;
    lua_package_path "/path/to/lua-nginx-statistics/?.lua;;";
    log_by_lua_file "/path/to/lua-nginx-statistics/statistics.lua";
```

[Back to TOC](#table-of-contents)

Author
======

xiaoxuanzi xiaoximou@gmail.com

[Back to TOC](#table-of-contents)

Copyright and License
=====================
The MIT License (MIT)
Copyright (c) 2017 xiaoxuanzi xiaoximou@gmail.com

[Back to TOC](#table-of-contents)

See Also
========
* the ngx_lua module: https://github.com/openresty/lua-nginx-module

[Back to TOC](#table-of-contents)

