function sleep() {
    return new Promise((resolve) => setTimeout(resolve, 1000));
  }

  sleep().then(() => {
        window.history.back()
})