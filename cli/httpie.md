# httpie — 接口冒烟探测（test-engineer）

希仁做接口冒烟/手探的 CLI HTTP 客户端：起服务后打 localhost，看状态码与响应体。
可重复的接口断言套件仍走 Java（MockMvc / REST Assured）。

## 安装
`brew install httpie`（提供 `http` / `https` 命令）。

## 常用
- GET：`http :8080/api/health`（`:8080` 即 `localhost:8080`）
- 带查询：`http :8080/api/users id==1 active==true`
- POST JSON：`http POST :8080/api/users name=alice age:=30`（`:=` 传非字符串）
- 带 header / token：`http :8080/api/me Authorization:"Bearer xxx"`
- 只看响应头/状态：`http --headers :8080/api/health` / `http --print=h ...`

> 前提：先本地起服务（`mvn spring-boot:run` / `java -jar`）。冒烟探测用，不替代结构化接口断言。
