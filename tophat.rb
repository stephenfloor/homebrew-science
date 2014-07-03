require 'formula'

class Tophat < Formula
  homepage 'http://ccb.jhu.edu/software/tophat'
  url 'http://ccb.jhu.edu/software/tophat/downloads/tophat-2.0.12.tar.gz'
  sha1 '966f8748a55820dfb64d3a5618f38105858dff3e'

  depends_on 'samtools'
  depends_on 'boost'
  # bowtie or bowtie2 is required to execute tophat
  depends_on 'bowtie2' => :recommended

  # 1. Fix namespace issue in segment_juncs.cpp
  # 2. Fix "Variable length arrays using non-POD element types" error
  # in tophat_reports.cpp
  # Reported upstream:
  # https://groups.google.com/forum/#!topic/tuxedo-tools-users/hOOVgXwB0NQ
  def patches
     DATA
  end

  def install
    # This can only build serially, otherwise it errors with no make target.
    ENV.deparallelize

    # Must add this to fix missing boost symbols. Autoconf doesn't include it.
    ENV.append 'LIBS', '-lboost_system-mt -lboost_thread-mt'

    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make install"
  end

  test do
    # Run a simple test as described in
    # http://ccb.jhu.edu/software/tophat/tutorial.shtml#test
    curl *%w[-O http://ccb.jhu.edu/software/tophat/downloads/test_data.tar.gz]
    system *%w[tar xzf test_data.tar.gz]
    cd "test_data" do
      system "#{bin}/tophat -r 20 test_ref reads_1.fq reads_2.fq"
      File.read("tophat_out/align_summary.txt").include?("71.0% overall read mapping rate")
      assert_equal 0, $?.exitstatus
    end
  end
end

__END__
diff --git a/src/segment_juncs.cpp b/src/segment_juncs.cpp
index 80fb3b7..bc55db7 100644
--- a/src/segment_juncs.cpp
+++ b/src/segment_juncs.cpp
@@ -47,7 +47,6 @@

 using namespace seqan;
 using namespace std;
-using namespace __gnu_cxx;

 // daehwan //geo
 //#define B_DEBUG 1
diff --git a/src/tophat_reports.cpp b/src/tophat_reports.cpp
index 9d0a927..a403dbe 100644
--- a/src/tophat_reports.cpp
+++ b/src/tophat_reports.cpp
@@ -2784,10 +2784,10 @@ for (; deletion_iter != deletions.end(); ++deletion_iter)
 			fprintf(stderr, "Warning: %lu small overhang junctions!\n", (long unsigned int)small_overhangs);
 	 */

-	JunctionSet vfinal_junctions[num_threads];
-	InsertionSet vfinal_insertions[num_threads];
-	DeletionSet vfinal_deletions[num_threads];
-	FusionSet vfinal_fusions[num_threads];
+	JunctionSet * vfinal_junctions = new JunctionSet[num_threads];
+	InsertionSet * vfinal_insertions = new InsertionSet[num_threads];
+	DeletionSet * vfinal_deletions = new DeletionSet[num_threads];
+	FusionSet * vfinal_fusions = new FusionSet[num_threads];

 	vector<SAlignStats> alnStats(num_threads);

@@ -2931,6 +2931,11 @@ for (; deletion_iter != deletions.end(); ++deletion_iter)
 	}

 	fprintf(stderr, "Found %lu junctions from happy spliced reads\n", (long unsigned int)final_junctions.size());
+
+	delete[] vfinal_junctions;
+	delete[] vfinal_insertions;
+	delete[] vfinal_deletions;
+	delete[] vfinal_fusions;
 }

 void print_usage()
