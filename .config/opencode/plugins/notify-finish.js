export default async ({ $ }) => {
  return {
    event: async ({ event }) => {
      if (event.type === "session.idle") {
        await $`notify-send "OpenCode finished" "Agent completed - check response"`;
      }
    }
  };
};
