const wordData = {
  getTodayWords() {
    return {
      learned: [
        { text: 'Привет', audioUrl: '/assets/audio/privet.mp3', example: 'Привет, как дела?' },
      ],
      review: [
        { text: 'Спасибо', audioUrl: '/assets/audio/spasibo.mp3', example: 'Спасибо за помощь.' },
      ],
      newWords: [
        { text: 'До свидания', audioUrl: '/assets/audio/do_svidaniya.mp3', example: 'До свидания, увидимся завтра.' },
      ],
    };
  },
};

module.exports = wordData;
