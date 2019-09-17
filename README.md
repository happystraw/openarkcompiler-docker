# 方舟编译器Docker环境

> 可以编译通过示例代码 `helloworld` 等
>
> 参考内容: https://zhuanlan.zhihu.com/p/81340230

## 使用方法

```bash
# 镜像很大(5.28GB), 推荐可以自己本地进行构建
docker pull happystraw/openarkcompiler

docker run --rm -it happystraw/openarkcompiler bash

# 测试编译
cd sample/helloworld
make
```

## 本地构建

可以根据自己需要修改

```bash
docker build -t happystraw/openarkcompiler .
```