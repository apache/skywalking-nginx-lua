# Release Guide
All committer should follow these steps to do release for this repo.

1. Update the [CHANGES.md](CHANGES.md) to prepare the official release. 

2. Package the source release.

```shell
> export VERSION=x.y.z
> make release-src
```

Use SVN to upload the files(tgz, asc and sha512) in the `release` folder to `https://dist.apache.org/repos/dist/dev/skywalking/nginx-lua/x.y.z`.

3. Make the internal announcements. Send an announcement mail in dev mail list.

```
[ANNOUNCE] SkyWalking Nginx LUA x.y.z test build available

The test build of x.y.z is available.

This is our Apache release.
We welcome any comments you may have, and will take all feedback into
account if a quality vote is called for this build.

Release notes:

 * https://github.com/apache/skywalking-nginx-lua/blob/vx.y.z/CHANGES.md

Release Candidate:

 * https://dist.apache.org/repos/dist/dev/skywalking/nginx-lua/x.y.z/
 * sha512 checksums
   - xxxxxxx  skywalking-nginx-lua-x.y.z-src.tgz

Release Tag :

 * vx.y.z

Release CommitID :

 * https://github.com/apache/skywalking-nginx-lua/tree/xxxxxxxxxx

Keys to verify the Release Candidate :

 * https://dist.apache.org/repos/dist/release/skywalking/KEYS


A vote regarding the quality of this test build will be initiated
within the next couple of days.
```

4. Wait at least 48 hours for test responses. If there is a critical issue found and confirmed by the PMC, this release should be cancelled.

5. Call for a vote. Call a vote in dev@skywalking.apache.org

```
[VOTE] Release SkyWalking Nginx LUA x.y.z 

This is a call for vote to release Apache SkyWalking Nginx LUA version x.y.z.

Release notes:

 * https://github.com/apache/skywalking-nginx-lua/blob/vx.y.z/CHANGES.md

Release Candidate:

 * https://dist.apache.org/repos/dist/dev/skywalking/nginx-lua/x.y.z/
 * sha512 checksums
   - xxxxxxx  skywalking-nginx-lua-x.y.z-src.tgz

Release Tag :

 * vx.y.z

Release CommitID :

 * https://github.com/apache/skywalking-nginx-lua/tree/xxxxxxxxxx

Keys to verify the Release Candidate :

 * https://dist.apache.org/repos/dist/release/skywalking/KEYS


A vote regarding the quality of this test build will be initiated
within the next couple of days.
```

5. Publish release, if vote passed.

Move the release from RC folder to the dist folder. This will begin the file sync across the global Apache mirrors.
```
> export SVN_EDITOR=vim
> svn mv https://dist.apache.org/repos/dist/dev/skywalking/nginx-lua/x.y.z https://dist.apache.org/repos/dist/release/skywalking/nginx-lua
....
enter your apache password
....

Send ANNOUNCE mail to dev@skywalking.apache.org
```
Mail title: [ANNOUNCE] Release Apache SkyWalking Nginx LUA version x.y.z

Mail content:
Hi all,

Apache SkyWalking  Team is glad to announce the first release of Apache SkyWalking Nginx LUA x.y.z

SkyWalking: APM (application performance monitor) tool for distributed systems, 
especially designed for microservices, cloud native and container-based (Docker, Kubernetes, Mesos) architectures. 

SkyWalking Nginx Agent provides the native tracing capability for Nginx powered by Nginx LUA module.

Vote Thread: 

Download Links : http://skywalking.apache.org/downloads/

Release Notes : https://github.com/apache/skywalking-nginx-lua/blob/vx.y.z/CHANGES.md

Website: http://skywalking.apache.org/

SkyWalking Resources:
- Issue: https://github.com/apache/skywalking/issues
- Mailing list: dev@skywalkiing.apache.org
- Documents: https://github.com/apache/skywalking-nginx-lua/tree/vx.y.z


- Apache SkyWalking Team
- ```