
# How to run locally

System:
- Ubuntu@25
- pnpm@10.17.0
- node@24.7

dev
```shell
export NODE_OPTIONS=--no-experimental-strip-types
pnpm i
sudo chown root node_modules/electron/dist/chrome-sandbox
sudo chmod 4755 node_modules/electron/dist/chrome-sandbox
pnpm start
```

prod on linux
```shell
pnpm make
sudo chown root out/dancerm-linux-x64/chrome-sandbox && sudo chmod 4755 out/dancerm-linux-x64/chrome-sandbox 
out/dancerm-linux-x64/dancerm
```

Boilerplate from https://github.com/Pandoks/sveltronkit
