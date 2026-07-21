# Azure Inventory & Insights Reports

現在ログイン中の Azure サブスクリプションを対象に、リソース / RBAC / NSG / Microsoft Defender for Cloud / Azure Advisor の情報を PowerShell で収集し、CSV / JSON のローデータと総合 HTML レポートを 1 本生成するリポジトリです。

GitHub Copilot の prompt から対話的に実行することも、PowerShell スクリプトを直接実行することもできます。

> 重要: 本リポジトリはデモ / 学習目的のサンプルコードです。Microsoft 公式製品ではなく、無保証 (AS-IS) で提供されます。本番環境で使用する場合は、お客様自身で十分なレビューとテストを実施してください。詳細は [LICENSE](LICENSE) を参照してください。

## できること

| ドメイン | 取得対象 | 出力 |
| --- | --- | --- |
| リソース | `Get-AzResource` 全リソース | CSV / JSON |
| RBAC | `Get-AzRoleAssignment` 全割り当て | CSV / JSON |
| NSG | `Get-AzNetworkSecurityGroup` のルールをフラット化 | CSV / JSON |
| Microsoft Defender for Cloud | `Microsoft.Security/assessments` REST API | CSV / JSON |
| Azure Advisor | `Get-AzAdvisorRecommendation` | CSV / JSON |
| 総合レポート | 上記 5 ドメイン横断分析 | HTML |

総合レポートには以下を含みます。

- エグゼクティブ サマリ
- ドメイン別サマリ表
- 潜在リスク Top 5
- 30 日アクション プラン
- NSG / Defender / Advisor の付録一覧

## 前提条件

- PowerShell 7.x 以上
- Az モジュール
- `Az.Accounts`, `Az.Resources`, `Az.Network` は必須
- `Az.Advisor` は推奨
- 対象 Azure サブスクリプションへの Reader 以上の権限
- Defender for Cloud の評価取得には Security Reader ロール

## セットアップ

```powershell
Install-Module -Name Az         -Scope CurrentUser -Repository PSGallery -Force
Install-Module -Name Az.Advisor -Scope CurrentUser -Repository PSGallery -Force

Connect-AzAccount
Set-AzContext -Subscription "<サブスクリプション名 または ID>"
```

## 使い方

すべてのスクリプトは引数なしで実行できます。出力先は既定で `output/` ディレクトリです。

```powershell
cd scripts

./Export-AzResources.ps1
./Export-AzRoleAssignments.ps1
./Export-AzNsgRules.ps1
./Export-AzDefenderRecommendations.ps1
./Export-AzAdvisorRecommendations.ps1
./New-AzComprehensiveAdminReport.ps1
```

主な成果物:

- `output/resources.{csv,json}`
- `output/rbac.{csv,json}`
- `output/nsg-rules.{csv,json}`
- `output/defender-recommendations.{csv,json}`
- `output/advisor-recommendations.{csv,json}`
- `output/comprehensive-report.html`

## ディレクトリ構成

```
.
├── README.md
├── LICENSE
├── .gitignore
├── .github/
│   └── prompts/
│       └── azure-comprehensive-report.prompt.md
├── scripts/
│   ├── Export-AzResources.ps1
│   ├── Export-AzRoleAssignments.ps1
│   ├── Export-AzNsgRules.ps1
│   ├── Export-AzDefenderRecommendations.ps1
│   ├── Export-AzAdvisorRecommendations.ps1
│   ├── New-AzComprehensiveAdminReport.ps1
│   ├── New-AzComprehensiveAdminReportWithAi.ps1
│   └── Test-AzComprehensiveAdminReport.ps1
└── output/
```

## Copilot prompt での実行

VS Code + GitHub Copilot Chat 環境では、以下の prompt を使って一連の収集とレポート生成を実行できます。

```text
/azure-comprehensive-report
```

## GitHub Actions でAPI経由のAI HTML生成

このリポジトリでは、パターンXのローカル実行フローをできる限り維持しながら、GitHub Actions上でAPI経由のAI HTMLレポート生成ができます。

パターンXから変えないもの:

- 既存のAzure棚卸し収集スクリプト
- 既存の5ドメイン出力: `resources.json`, `rbac.json`, `nsg-rules.json`, `defender-recommendations.json`, `advisor-recommendations.json`
- 既存のルールベースHTML生成スクリプト
- 生成HTML名: `comprehensive-report.html`
- `reports/latest` / `reports/history` への保存

- 収集ワークフロー: `.github/workflows/azure-report-public.yml`
- 分析ワークフロー: `.github/workflows/azure-report-api-generate.yml`
- 公開ワークフロー: `.github/workflows/azure-report-api-publish.yml`
- AI 生成スクリプト: `scripts/New-AzComprehensiveAdminReportWithAi.ps1`
- 検証スクリプト: `scripts/Test-AzComprehensiveAdminReport.ps1`
- 生成物:
	- `output/comprehensive-report.html`
	- `output/report-evidence.json`
	- `reports/latest/comprehensive-report.html`
	- `reports/history/{yyyy-MM-dd}/comprehensive-report.html`

本番経路は、Azure 収集、API 経由のAI分析、公開を別workflowへ分離しています。

1. `Azure 棚卸しレポート - API 1/3 収集`: Azure OIDC でログインし、5ドメインのrawデータを収集する
2. `Azure 棚卸しレポート - API 2/3 分析`: 収集Artifactを取得し、API経由でAI HTMLを生成して検証する
3. `Azure 棚卸しレポート - API 3/3 公開`: 検証済みArtifactを `reports/latest` / `reports/history` / Pages 用 `_site` へ反映する

必要な設定:

- Secret:
	- `AI_REPORT_API_KEY`
- Variable（任意）:
	- `AI_REPORT_API_ENDPOINT`
	- `AI_REPORT_MODEL`
	- `ENABLE_GITHUB_PAGES`（`true` のときのみ Pages デプロイ）

`Azure 棚卸しレポート - API 1/3 収集` の `workflow_dispatch` で `report_mode` を選択できます。選択値は `workflow-metadata.json` として収集Artifactに保存され、後続の分析workflowへ引き継がれます。

- `auto`（既定）: AI を試行し、失敗または Secret 未設定時は rule-based にフォールバック
- `ai-only`: AI 生成のみ実行。失敗時はジョブ失敗
- `rule-based`: AI を使わず `New-AzComprehensiveAdminReport.ps1` のみ実行

> 補足:
> - AI 生成が失敗した場合は、既存のルールベース HTML 生成 (`New-AzComprehensiveAdminReport.ps1`) にフォールバックして処理を継続します。
> - `output/report-evidence.json` に `generation_method=api-ai` または `generation_method=rule-based-fallback` を記録します。
> - `azure-comprehensive-report.prompt.md` を seed として利用し、API呼び出し時のプロンプトで事実拘束ルールを適用します。

権限境界:

- Azure OIDC の `id-token: write` は収集workflowだけに付与
- GitHub Models / AI API 呼び出しとレポート検証は分析workflowで実行
- `contents: write` と Pages 公開権限は公開workflowだけに付与

## セキュリティと取り扱い上の注意

- 生成物にはサブスクリプション ID、リソース ID、プリンシパル名、IP アドレス、NSG ルール、セキュリティ評価結果が含まれます。社外共有前に必ず確認してください。
- `output/` は `.gitignore` 対象です。Git でコミットしないでください。
- 収集対象を制限したい場合は、`Export-Az*.ps1` を編集してリソースグループ / リソースタイプ / スコープでフィルタしてください。
- HTML はローカル閲覧を想定しています。
- 本ツールは読み取りのみを行い、Azure リソースの作成・変更・削除は行いません。

## ライセンス

[MIT License](LICENSE)
