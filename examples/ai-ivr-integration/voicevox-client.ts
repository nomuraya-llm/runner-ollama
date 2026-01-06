/**
 * VOICEVOX APIクライアント
 * AI-IVR統合用のシンプルなラッパー
 */

export interface VoicevoxSpeaker {
  name: string;
  speaker_uuid: string;
  styles: VoicevoxStyle[];
}

export interface VoicevoxStyle {
  name: string;
  id: number;
}

export interface VoicevoxSynthesisOptions {
  speedScale?: number;      // 話速（0.5〜2.0、デフォルト: 1.0）
  pitchScale?: number;       // 音高（-0.15〜0.15、デフォルト: 0.0）
  intonationScale?: number;  // 抑揚（0.0〜2.0、デフォルト: 1.0）
  volumeScale?: number;      // 音量（0.0〜2.0、デフォルト: 1.0）
}

export class VoicevoxClient {
  private baseUrl: string;

  constructor(baseUrl: string = 'http://localhost:50021') {
    this.baseUrl = baseUrl;
  }

  /**
   * VOICEVOXサーバーの起動確認
   */
  async checkStatus(): Promise<boolean> {
    try {
      const response = await fetch(`${this.baseUrl}/speakers`);
      return response.ok;
    } catch {
      return false;
    }
  }

  /**
   * 利用可能な話者一覧を取得
   */
  async getSpeakers(): Promise<VoicevoxSpeaker[]> {
    const response = await fetch(`${this.baseUrl}/speakers`);
    if (!response.ok) {
      throw new Error(`VOICEVOX API error: ${response.status}`);
    }
    return response.json();
  }

  /**
   * 話者IDから話者情報を取得
   */
  async getSpeakerInfo(speakerId: number): Promise<VoicevoxSpeaker | null> {
    const speakers = await this.getSpeakers();
    for (const speaker of speakers) {
      const style = speaker.styles.find(s => s.id === speakerId);
      if (style) {
        return speaker;
      }
    }
    return null;
  }

  /**
   * テキストから音声クエリを生成
   */
  private async createAudioQuery(
    text: string,
    speakerId: number
  ): Promise<any> {
    const response = await fetch(
      `${this.baseUrl}/audio_query?text=${encodeURIComponent(text)}&speaker=${speakerId}`,
      { method: 'POST' }
    );

    if (!response.ok) {
      throw new Error(`VOICEVOX API error: ${response.status}`);
    }

    return response.json();
  }

  /**
   * 音声クエリから音声を合成
   */
  private async synthesize(
    query: any,
    speakerId: number
  ): Promise<ArrayBuffer> {
    const response = await fetch(
      `${this.baseUrl}/synthesis?speaker=${speakerId}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(query),
      }
    );

    if (!response.ok) {
      throw new Error(`VOICEVOX API error: ${response.status}`);
    }

    return response.arrayBuffer();
  }

  /**
   * テキストを音声に変換
   * @param text 読み上げるテキスト
   * @param speakerId 話者ID（1: 四国めたん, 3: ずんだもん など）
   * @param options 合成オプション
   * @returns WAV形式の音声データ（ArrayBuffer）
   */
  async speak(
    text: string,
    speakerId: number = 1,
    options: VoicevoxSynthesisOptions = {}
  ): Promise<ArrayBuffer> {
    // 音声クエリ生成
    const query = await this.createAudioQuery(text, speakerId);

    // オプションを適用
    if (options.speedScale !== undefined) {
      query.speedScale = options.speedScale;
    }
    if (options.pitchScale !== undefined) {
      query.pitchScale = options.pitchScale;
    }
    if (options.intonationScale !== undefined) {
      query.intonationScale = options.intonationScale;
    }
    if (options.volumeScale !== undefined) {
      query.volumeScale = options.volumeScale;
    }

    // 音声合成
    return this.synthesize(query, speakerId);
  }

  /**
   * 音声データをブラウザで再生
   */
  async playAudio(audioData: ArrayBuffer): Promise<void> {
    const audioContext = new AudioContext();
    const audioBuffer = await audioContext.decodeAudioData(audioData);

    const source = audioContext.createBufferSource();
    source.buffer = audioBuffer;
    source.connect(audioContext.destination);

    return new Promise((resolve) => {
      source.onended = () => resolve();
      source.start();
    });
  }

  /**
   * テキストを読み上げる（ワンステップ）
   */
  async speakAndPlay(
    text: string,
    speakerId: number = 1,
    options: VoicevoxSynthesisOptions = {}
  ): Promise<void> {
    const audio = await this.speak(text, speakerId, options);
    await this.playAudio(audio);
  }
}

// よく使う話者ID
export const VOICEVOX_SPEAKERS = {
  SHIKOKU_METAN_NORMAL: 2,      // 四国めたん（ノーマル）
  SHIKOKU_METAN_SWEET: 0,       // 四国めたん（あまあま）
  ZUNDAMON_NORMAL: 3,           // ずんだもん（ノーマル）
  ZUNDAMON_SWEET: 1,            // ずんだもん（あまあま）
  KASUKABE_TSUMUGI: 8,          // 春日部つむぎ
  HAAU: 10,                     // 波音リツ
};

// 使用例
/*
const client = new VoicevoxClient();

// サーバー起動確認
const isRunning = await client.checkStatus();
console.log('VOICEVOX running:', isRunning);

// 話者一覧取得
const speakers = await client.getSpeakers();
console.log('Available speakers:', speakers.map(s => s.name));

// 音声合成
const audio = await client.speak('こんにちは、四国めたんです', VOICEVOX_SPEAKERS.SHIKOKU_METAN_NORMAL);

// ブラウザで再生
await client.playAudio(audio);

// または、ワンステップで再生
await client.speakAndPlay('こんにちは', VOICEVOX_SPEAKERS.ZUNDAMON_NORMAL);

// オプション付き
await client.speakAndPlay(
  'ゆっくり話します',
  VOICEVOX_SPEAKERS.ZUNDAMON_NORMAL,
  { speedScale: 0.8, pitchScale: 0.05 }
);
*/
