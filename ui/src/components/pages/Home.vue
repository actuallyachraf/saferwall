<template>
  <p>
    <router-link :to="this.$routes.UPLOAD.path">go to upload</router-link>
  </p>
</template>

<script>
export default {
  name: "Home",
  data() {
    return {}
  },

  mounted() {},
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped></style>
