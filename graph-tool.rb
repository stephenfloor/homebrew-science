require 'formula'

class GraphTool < Formula
  homepage 'http://graph-tool.skewed.de/'
  url 'http://downloads.skewed.de/graph-tool/graph-tool-2.2.31.tar.bz2'
  sha1 '5e0b1c215ecd76191a82c745df0fac17e33bfb09'
  head 'https://github.com/count0/graph-tool.git'

  option 'without-cairo', 'Build without cairo support'

  depends_on 'pkg-config' => :build
  depends_on 'boost' => ['c++11', 'with-python']
  depends_on 'cgal' => 'c++11'
  depends_on 'google-sparsehash' => ['c++11', :recommended]
  depends_on 'cairomm' => 'c++11' if build.with? 'cairo'
  depends_on 'py2cairo' if build.with? 'cairo'
  depends_on 'matplotlib' => :python
  depends_on 'numpy' => :python
  depends_on 'scipy' => :python

  def install
    ENV.cxx11
    config_args = %W[
      --disable-debug
      --disable-dependency-tracking
      --disable-optimization
      --prefix=#{prefix}
      --with-python-module-path=#{lib}/python2.7/site-packages
    ]
    config_args << "--disable-cairo" if build.without? 'cairo'
    config_args << "--disable-sparsehash" if build.without? 'google-sparsehash'
    system "./configure", "PYTHON_EXTRA_LDFLAGS= ", *config_args
    system "make", "install"
  end

  test do
    Pathname('test.py').write <<-EOS.undent
      import graph_tool.all as gt
      g = gt.Graph()
      v1 = g.add_vertex()
      v2 = g.add_vertex()
      e = g.add_edge(v1, v2)
    EOS

    Language::Python.each_python(build) do |python, version|
      system python, "test.py"
    end
  end
end
