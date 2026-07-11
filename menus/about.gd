extends Control
# このゲームについて / The "About" panel.
# ゲームの目的の短い説明、チュートリアルサイトへのリンク、制作クレジット（自由記入）を出します。
# Shows a short "what this is" blurb, a link to the tutorial site, and free-text credits.
# 文章やクレジットは about.tscn とここの export で変えられるので、エンジンのコードは
# さわらずに編集できます。
# The text and credits are editable here (exports) and in about.tscn, so a teacher can
# change them without touching the engine code.
signal back_pressed

# 開くWebページ（チュートリアルサイト）。Inspector で変えられます。
# The web page the link opens (the tutorial site). Editable in the Inspector.
@export var site_url: String = "https://matsuyama-henrik-lab.github.io/seminar-land/"

# 表示する文章（自由記入）。空のままなら about.tscn に書いた既定のテキスト（Godot で…）を
# 使います。学生版では、ここに参加した学生のクレジットを入れて上書きできます。
# The text to show. If left empty, the scene's default blurb (the "Godot で…" text) is
# used. For a student build, put the students' credits here to override it.
@export_multiline var about_text: String = ""

func _ready() -> void:
	$Content/Box/Link.pressed.connect(_on_link_pressed)
	$Content/Box/Back.pressed.connect(func(): back_pressed.emit())
	if about_text.strip_edges() != "":
		$Content/Box/Purpose.text = about_text

# サイトをブラウザで開きます（デスクトップ）。Web版では新しいタブで開きます。
# Opens the site in the browser (desktop); on the web build it opens a new tab.
func _on_link_pressed() -> void:
	OS.shell_open(site_url)
