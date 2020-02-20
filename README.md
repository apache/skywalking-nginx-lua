Apache SkyWalking Nginx Agent
==========

<img src="http://skywalking.apache.org/assets/logo.svg" alt="Sky Walking logo" height="90px" align="right" />

[![Twitter Follow](https://img.shields.io/twitter/follow/asfskywalking.svg?style=for-the-badge&label=Follow&logo=twitter)](https://twitter.com/AsfSkyWalking)


**SkyWalking** Nginx Agent provides the native tracing capability for Nginx powered by Nginx LUA module. 

This agent follows the SkyWalking tracing and header protocol. It reports tracing data to SkyWalking APM through HTTP protocol. 
All HTTP 1.1 requests go through Nginx could be collected by this agent.

# Setup Doc
TODO

# APIs

# Set up dev env
All codes in the `lib/skywalking` require the `*_test.lua` to do the UnitTest. To run that, you need to install
- Lua 5.3
- LuaRocks

The following libs are required in runtime or test cases, please use `LuaRocks` to install them.
- luaunit
- luasocket


# Download
Have no release yet.

# Contact Us
* Submit an [issue](https://github.com/apache/skywalking/issues)
* Mail list: **dev@skywalking.apache.org**. Mail to `dev-subscribe@skywalking.apache.org`, follow the reply to subscribe the mail list.
* Join `skywalking` channel at [Apache Slack](https://join.slack.com/t/the-asf/shared_invite/enQtNzc2ODE3MjI1MDk1LTAyZGJmNTg1NWZhNmVmOWZjMjA2MGUyOGY4MjE5ZGUwOTQxY2Q3MDBmNTM5YTllNGU4M2QyMzQ4M2U4ZjQ5YmY). If the link is not working, find the latest one at [Apache INFRA WIKI](https://cwiki.apache.org/confluence/display/INFRA/Slack+Guest+Invites).
* QQ Group: 392443393(2000/2000, not available), 901167865(available)

# License
Apache 2.0