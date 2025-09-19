const Layout = () => import("@/layout/index.vue");

const systemRouter = {
  path: "/system",
  name: "System",
  component: Layout,
  redirect: "/system/user",
  meta: {
    icon: "ep:setting",
    title: "系统管理",
    rank: 8
  },
  children: [
    {
      path: "/system/user",
      name: "System-User",
      component: () => import("@/views/system/user/index.vue"),
      meta: {
        icon: "ri:admin-line",
        title: "用户管理",
        keepAlive: true,
        showParent: true
      }
    }
  ]
};

export default systemRouter as RouteConfigsTable;
