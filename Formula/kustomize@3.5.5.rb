class KustomizeAT355 < Formula
  desc "Template-free customization of Kubernetes YAML manifests"
  homepage "https://github.com/kubernetes-sigs/kustomize"
  url "https://github.com/kubernetes-sigs/kustomize.git",
      :tag      => "kustomize/v3.5.5",
      :revision => "897e7b6e61e65188d846c32bd3af9ef68b0f746a"
  head "https://github.com/kubernetes-sigs/kustomize.git"

  depends_on "go" => :build

  def install
    revision = Utils.popen_read("git", "rev-parse", "HEAD").strip

    cd "kustomize" do
      ldflags = %W[
        -s -X sigs.k8s.io/kustomize/api/provenance.version=kustomize/v#{version}
        -X sigs.k8s.io/kustomize/api/provenance.gitCommit=#{revision}
        -X sigs.k8s.io/kustomize/api/provenance.buildDate=#{Time.now.iso8601}
      ]
      system "go", "build", "-ldflags", ldflags.join(" "), "-o", bin/"kustomize"
    end
  end

  test do
    assert_match "kustomize/v#{version}", shell_output("#{bin}/kustomize version")

    (testpath/"kustomization.yaml").write <<~EOS
      resources:
      - service.yaml
      patchesStrategicMerge:
      - patch.yaml
    EOS
    (testpath/"patch.yaml").write <<~EOS
      apiVersion: v1
      kind: Service
      metadata:
        name: brew-test
      spec:
        selector:
          app: foo
    EOS
    (testpath/"service.yaml").write <<~EOS
      apiVersion: v1
      kind: Service
      metadata:
        name: brew-test
      spec:
        type: LoadBalancer
    EOS
    output = shell_output("#{bin}/kustomize build #{testpath}")
    assert_match /type:\s+"?LoadBalancer"?/, output
  end
end
