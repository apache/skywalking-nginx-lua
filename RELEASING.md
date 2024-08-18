# Apache SkyWalking Nginx LUA agent release guide

SkyWalking Nginx LUA agent released through source tar on the [website](https://skywalking.apache.org/downloads/#NginxLUAAgent) 
and [SkyWalking's LuaRock Module](https://luarocks.org/modules/apache-skywalking/skywalking-nginx-lua).

Release manager could follow this doc to build and upload a release for this agent.

1. Prepare the new `.rockspec` file for the new release. Ref previous and latest files in [here](./rockspec/).
2. Update the [changelogs](CHANGES.md) for the upcoming release.
3. Tag through git or GitHub.
4. Build the source tars with ASC sign and SHA512

```shell
> export RELEASE_VERSION=x.y.z

> tar czf skywalking-nginx-lua-${RELEASE_VERSION}-src.tgz \
    --exclude .git \
    --exclude .DS_Store \
    --exclude .github \
    --exclude .gitignore \
    --exclude .gitmodules \
    --exclude .mvn/wrapper/maven-wrapper.jar \
    skywalking-nginx-lua

> gpg --armor --detach-sig skywalking-nginx-lua-${RELEASE_VERSION}-src.tgz

> shasum -a 512 skywalking-nginx-lua-${RELEASE_VERSION}-src.tgz > skywalking-nginx-lua-${RELEASE_VERSION}-src.tgz.sha512

```

5. Upload `*-src.tgz`, `*-src.tgz.asc` and `*-src.tgz.sha512` to SVN `https://dist.apache.org/repos/dist/release/skywalking/nginx-lua/${RELEASE_VERSION}`

6. Call for vote through `dev@skywalking.apache.org` mailing list.

```
Hi all,

This is a call for vote to release Apache SkyWalking Nginx LUA version ${RELEASE_VERSION}.

Release notes:

 * https://github.com/apache/skywalking-nginx-lua/blob/v${RELEASE_VERSION}/CHANGES.md

Release Candidate:

 * https://dist.apache.org/repos/dist/dev/skywalking/nginx-lua/${RELEASE_VERSION}/
 * sha512 checksums
   - xxx  skywalking-nginx-lua-${RELEASE_VERSION}-src.tgz

Release Tag :

 * v${RELEASE_VERSION}

Release CommitID :

 * https://dist.apache.org/repos/dist/dev/skywalking/nginx-lua/${COMMIT_ID}

Keys to verify the Release Candidate :

 * https://dist.apache.org/repos/dist/release/skywalking/KEYS


Voting will start now (Date) and will remain open for at least
72 hours, Request all PMC members to give their vote.
[ ] +1 Release this package.
[ ] +0 No opinion.
[ ] -1 Do not release this package because....
```

7. If the vote passed with at least +1 binding(s) and more +1 binding(s) than -1 binding(s), the vote pass.

8. Upload the rockspec to LuaRocks

// As a release manager, you could ask the luarocks account in the private mail list, and get this API key to upload the new release.

> luarocks upload skywalking-nginx-lua-${RELEASE_VERSION}-0.rockspec --api-key=xxx

9. Move the source tar from svn dev folder to the release folder. 

> svn mv https://dist.apache.org/repos/dist/dev/skywalking/nginx-lua/${RELEASE_VERSION} https://dist.apache.org/repos/dist/release/skywalking/nginx-lua

10. Update website event page accordingly.