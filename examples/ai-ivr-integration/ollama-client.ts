/**
 * Ollama APIクライアント
 * AI-IVR統合用のシンプルなラッパー
 */

export interface OllamaMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

export interface OllamaGenerateOptions {
  model?: string;
  temperature?: number;
  maxTokens?: number;
}

export class OllamaClient {
  private baseUrl: string;
  private defaultModel: string;

  constructor(baseUrl: string = 'http://localhost:11434', defaultModel: string = 'phi3.5:latest') {
    this.baseUrl = baseUrl;
    this.defaultModel = defaultModel;
  }

  /**
   * Ollamaサーバーの起動確認
   */
  async checkStatus(): Promise<boolean> {
    try {
      const response = await fetch(`${this.baseUrl}/api/tags`);
      return response.ok;
    } catch {
      return false;
    }
  }

  /**
   * インストール済みモデル一覧を取得
   */
  async listModels(): Promise<string[]> {
    try {
      const response = await fetch(`${this.baseUrl}/api/tags`);
      const data = await response.json();
      return data.models?.map((m: any) => m.name) || [];
    } catch {
      return [];
    }
  }

  /**
   * シンプルなチャット
   */
  async chat(
    message: string,
    options: OllamaGenerateOptions = {}
  ): Promise<string> {
    const model = options.model || this.defaultModel;

    const response = await fetch(`${this.baseUrl}/api/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model,
        prompt: message,
        stream: false,
        options: {
          temperature: options.temperature ?? 0.7,
          num_predict: options.maxTokens ?? 500,
        },
      }),
    });

    if (!response.ok) {
      throw new Error(`Ollama API error: ${response.status}`);
    }

    const data = await response.json();
    return data.response;
  }

  /**
   * 会話履歴を含むチャット
   */
  async chatWithHistory(
    messages: OllamaMessage[],
    options: OllamaGenerateOptions = {}
  ): Promise<string> {
    const model = options.model || this.defaultModel;

    const response = await fetch(`${this.baseUrl}/api/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model,
        messages,
        stream: false,
        options: {
          temperature: options.temperature ?? 0.7,
          num_predict: options.maxTokens ?? 500,
        },
      }),
    });

    if (!response.ok) {
      throw new Error(`Ollama API error: ${response.status}`);
    }

    const data = await response.json();
    return data.message.content;
  }

  /**
   * ストリーミング応答
   */
  async *chatStream(
    message: string,
    options: OllamaGenerateOptions = {}
  ): AsyncGenerator<string, void, unknown> {
    const model = options.model || this.defaultModel;

    const response = await fetch(`${this.baseUrl}/api/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model,
        prompt: message,
        stream: true,
        options: {
          temperature: options.temperature ?? 0.7,
          num_predict: options.maxTokens ?? 500,
        },
      }),
    });

    if (!response.ok) {
      throw new Error(`Ollama API error: ${response.status}`);
    }

    const reader = response.body?.getReader();
    if (!reader) {
      throw new Error('Response body is not readable');
    }

    const decoder = new TextDecoder();
    let buffer = '';

    try {
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n');
        buffer = lines.pop() || '';

        for (const line of lines) {
          if (line.trim()) {
            const data = JSON.parse(line);
            if (data.response) {
              yield data.response;
            }
          }
        }
      }
    } finally {
      reader.releaseLock();
    }
  }
}

// 使用例
/*
const client = new OllamaClient();

// サーバー起動確認
const isRunning = await client.checkStatus();
console.log('Ollama running:', isRunning);

// シンプルなチャット
const response = await client.chat('こんにちは');
console.log('Response:', response);

// 会話履歴付き
const messages = [
  { role: 'system', content: 'あなたは親切なアシスタントです' },
  { role: 'user', content: 'こんにちは' },
  { role: 'assistant', content: 'こんにちは！何かお手伝いできることはありますか？' },
  { role: 'user', content: '東京の天気は？' },
];
const response2 = await client.chatWithHistory(messages);
console.log('Response:', response2);

// ストリーミング
for await (const chunk of client.chatStream('東京の観光地を教えて')) {
  process.stdout.write(chunk);
}
*/
