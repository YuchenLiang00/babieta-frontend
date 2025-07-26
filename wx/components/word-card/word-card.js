Component({
  properties: {
    word: Object,
  },

  methods: {
    playAudio() {
      wx.playBackgroundAudio({
        dataUrl: this.properties.word.audioUrl,
      });
    },

    showExample() {
      wx.showModal({
        title: '例句',
        content: this.properties.word.example,
        showCancel: false,
      });
    },

    markMastered() {
      this.triggerEvent('onMastered', { word: this.properties.word });
    },

    markReviewLater() {
      this.triggerEvent('onReviewLater', { word: this.properties.word });
    },
  },
});
