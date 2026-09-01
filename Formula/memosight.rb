class Memosight < Formula
  include Language::Python::Virtualenv

  desc "Local-first image-to-structured-visual-text CLI"
  homepage "https://github.com/MemoBloom/MemoSight"
  url "file:///Users/kanzhiwu/Workspace/memosight/.worktrees/brew-release/dist/memosight-0.1.0.tar.gz"
  sha256 "1af9e22842d4e9f408ddbace4ccba95dc1f590c34e4825ff5b505d24b5d287f2"
  license "MIT"

  depends_on "python@3.13"

  resource "annotated-types" do
    url "https://files.pythonhosted.org/packages/5f/56/a8120250d128bed162cd73c76d45f6ef9991f3e068f62a8ee060afa3104a/annotated_types-0.8.0.tar.gz"
    sha256 "13b2beaad985e05e2d6407ee4c4f35590b11f8d693a258a561055cac8f64cab7"
  end

  resource "anyio" do
    url "https://files.pythonhosted.org/packages/61/cc/a381afa6efea9f496eff839d4a6a1aed3bfafc7b3ab4b0d1b243a12573dd/anyio-4.14.2.tar.gz"
    sha256 "cfa139f3ed1a23ee8f88a145ddb5ac7605b8bbfd8592baacd7ce3d8bb4313c7f"
  end

  resource "certifi" do
    url "https://files.pythonhosted.org/packages/a3/c2/24167ea9858356b47a87a50d39908bfdb72ceeefe0041586e704e5376b3a/certifi-2026.7.22.tar.gz"
    sha256 "741e2c3b351ddf169a738da9f2c048608ff7f2c5cc02f1ebc6b118bb090d5d55"
  end

  resource "h11" do
    url "https://files.pythonhosted.org/packages/01/ee/02a2c011bdab74c6fb3c75474d40b3052059d95df7e73351460c8588d963/h11-0.16.0.tar.gz"
    sha256 "4e35b956cf45792e4caa5885e69fba00bdbc6ffafbfa020300e549b208ee5ff1"
  end

  resource "httpcore" do
    url "https://files.pythonhosted.org/packages/06/94/82699a10bca87a5556c9c59b5963f2d039dbd239f25bc2a63907a05a14cb/httpcore-1.0.9.tar.gz"
    sha256 "6e34463af53fd2ab5d807f399a9b45ea31c3dfa2276f15a2c3f00afff6e176e8"
  end

  resource "httpx" do
    url "https://files.pythonhosted.org/packages/b1/df/48c586a5fe32a0f01324ee087459e112ebb7224f646c0b5023f5e79e9956/httpx-0.28.1.tar.gz"
    sha256 "75e98c5f16b0f35b567856f597f06ff2270a374470a5c2392242528e3e3e42fc"
  end

  resource "idna" do
    url "https://files.pythonhosted.org/packages/5f/f7/abb373e5757eaec4b922b92f97ec8d6d7e057cf06778247604fbc4e7c3f3/idna-3.19.tar.gz"
    sha256 "5e0811a4383b21dc5838069f801c4fb62113b7447663d2530d2bd6e77b49bf15"
  end

  resource "pydantic" do
    url "https://files.pythonhosted.org/packages/53/ef/fc4f868f4e2cee79f863883abffceff107875f569b848507319842d2a681/pydantic-2.13.5.tar.gz"
    sha256 "51a9c5f7b2f8e636f04c6cada605d9b6a3bf1348fdf945a3d8869b19bba0ee08"
  end

  # Pinned platform wheel: a from-source build with the local beta toolchain
  # produces a malformed .so (mis-aligned LINKEDIT string pool on macOS 27).
  resource "pydantic-core" do
    url "https://files.pythonhosted.org/packages/21/43/6323b1f8b217780454c61304bcd2b38ae4762f50754414124603ccc90bb2/pydantic_core-2.46.5-cp313-cp313-macosx_11_0_arm64.whl"
    sha256 "f332f0e72a5a0400141f830744e141bf9f97917878dbe968669e8a7fefea78ff"
  end

  resource "typing-extensions" do
    url "https://files.pythonhosted.org/packages/f6/cc/6253133b5bb138fc3306cebfbda2c520f545d36b5be2c7255cc528bb45d6/typing_extensions-4.16.0.tar.gz"
    sha256 "dc983d19a509c94dba722ee6abd33940f7c05a89e243c47e907eb4db6f1a43e5"
  end

  resource "typing-inspection" do
    url "https://files.pythonhosted.org/packages/a3/26/b09b8010994eccc3c09092e6b34058f36a460eea2d4c3e8b910c695975a0/typing_inspection-0.4.4.tar.gz"
    sha256 "547274fa6b0a561ccf549cc9524b999a578e737d015d8709d021f9d0d13bea47"
  end

  def install
    virtualenv_install_with_resources without: ["pydantic-core"]
    # Homebrew's pip_install only accepts py3-none-any wheels; install the
    # pinned platform wheel directly (sha256 is verified on download). The
    # brew cache filename has a hash prefix that pip rejects, so copy it to
    # its canonical wheel name first.
    wheel = buildpath/resource("pydantic-core").downloader.basename
    cp resource("pydantic-core").cached_download, wheel
    system "python3.13", "-m", "pip", "--python=#{libexec}/bin/python",
           "install", "--verbose", "--no-deps", "--ignore-installed", wheel
  end

  test do
    assert_match "memosight", shell_output("#{bin}/memosight --help")
    assert_match version.to_s, shell_output("#{bin}/memosight --version")

    # doctor without a running server must diagnose cleanly, not crash.
    ENV["MEMOSIGHT_MLX_SERVER_URL"] = "http://127.0.0.1:59999"
    doctor_output = shell_output("#{bin}/memosight doctor", 1)
    assert_match "FAIL", doctor_output
    assert_match "memosight serve --model", doctor_output

    # analyze with the offline mock backend must emit valid JSON.
    (testpath/"photo.jpg").write("\xFF\xD8\xFF")
    output = shell_output("#{bin}/memosight analyze #{testpath}/photo.jpg --backend mock")
    payload = JSON.parse(output)
    assert_equal "ok", payload["status"]
    assert_equal "mock caption", payload.dig("observation", "caption")
  end
end
