
# How to run locally

System:
- Ubuntu@25
- pnpm@10.17.0
- node@24.7

```shell
export NODE_OPTIONS=--no-experimental-strip-types
pnpm i
sudo chown root node_modules/electron/dist/chrome-sandbox
sudo chmod 4755 node_modules/electron/dist/chrome-sandbox
pnpm start
```

Boilerplate from https://github.com/Pandoks/sveltronkit

# To be solved

Why do we need to apply the @sveltejs/kit patches? lines have changed and the patch isn't applied now