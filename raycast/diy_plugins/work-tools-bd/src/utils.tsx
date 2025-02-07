const fs = require("fs");
const yaml = require("js-yaml");

// 读取并解析 YAML 文件
export function loadYAML(filePath) {
  try {
    const fileContents = fs.readFileSync(filePath, "utf8");
    return yaml.load(fileContents);
  } catch (e) {
    console.error(e);
    showToast(ToastStyle.Failure, "Failed to load YAML file");
    return null;
  }
}

// 搜索函数
export function searchObject(objects, query) {
  if (query === "") {
    return objects;
  }
  // console.log("query", query);

  const results = [];
  if (objects instanceof Array) {
    for (const item of Object.values(objects)) {
      if (item.key.includes(query)) {
        results.push(item);
      }
    }
  } else {
    for (const [key, value] of Object.entries(objects)) {
      if (key.includes(query)) {
        results.push({ name: key, path: value });
      }
    }
  }

  return results;
}
