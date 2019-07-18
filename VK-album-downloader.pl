use LWP::UserAgent;

$url = shift || die " [+] Usage: perl $0 [URL]\n";
unless($url =~ /^https?:\/\/vk\.com\/(\w+)$/) {
	die " [!] The URL prefix should start with \"https://vk.com/\"\n";
}

($albumName) = $url =~ /.*\/(\w+)$/;
$previewFolder = $albumName . "-preview";
$imageFolder = $albumName . "-image";

print " [+] VK album downloader\n";
print " [+] Download only preview [y/N]: ";
chomp($input = <STDIN>);
$isPreview = uc($input) eq 'Y' ? "true" : "false";
print " [+] Checking media files on url: $url\n";

$agent = LWP::UserAgent->new();

$offset = 0;
do {
	$checkLastOffset = $offset;
	$content = $agent->post($url,[
		"al" => "1",
		"offset" => $offset,
		"part" => "1"
	])->content;

	while($content =~ /background-image: url\((.*?)\)/g) {
		$imageURL = $1;
		push(@imageURLs, $imageURL);
		$offset++;
	}
} until($checkLastOffset == $offset);

print " [+] Found $offset images.\n";
sleep(1);

if($isPreview eq "true") {
	mkdir($previewFolder);
	print " [+] Downloading preview images...\n";
	foreach $imageURL (@imageURLs) {
		($imageName) = $imageURL =~ /.*\/(.*)$/;
		print "     => $imageURL\n";
		download($imageURL,$previewFolder."/".$imageName);
	}
	exit;
}

mkdir($imageFolder);
$imageCount = $offset;
$offset = 0;

print " [+] Downloading full images...\n";
do {
	$content = $agent->post('https://vk.com/al_photos.php',[
		"act" => "show",
		"al" => "1",
		"direction" => "1",
		"list" => $albumName,
		"offset" => $offset
	])->content;
	@contentArray = split(/"id":/, $content);
	foreach $content (@contentArray) {
		if($content =~ /^"(.*?)".*_src":"(.*?)"/g) {
			$id = $1;
			$imageURL = $2;
			$imageURL =~ s/\\\//\//g;
			($imageName) = $imageURL =~ /.*\/(.*)$/;
			$offset++;
			print "     => [$offset/$imageCount][ID:$id] $imageURL\n";
			download($imageURL,$imageFolder."/".$imageName);
			last if($offset >= $imageCount);
		}
	}
} until($offset >= $imageCount);

sub download {
	my $download = $agent->get($_[0])->content;
	open IMG, ">$_[1]";
	binmode IMG;
	print IMG $download;
	close IMG;
}
