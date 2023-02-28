#use utf8;
use strict;
#use warnings;

#$diskroot = "../../";

my $source="problem1";
my $comb = "";
my $test = "";
my $gtest = "";
my $GUID;
my (%seen,%guidseen) = "";
my @regions;
my @lines;
my @array;
my %TYPE_FOUND;
my %NAME_FOUND;
my %NAME_TO_CODE;
my %seenCULT;
my (%BLOB, %IMAGE_found, $PDcat, $PDurl, $newIMAGEid, $count_images_new, $count_images,$PDproj) = "";
my (%FAM_LIC, %FAM_FUN, %FAM_BR, %FAM_PT, %FAM_SP, %FAM_ALG) = "";
my (%PR_found, %PHfound, %E_FOUND, %F_FOUND, %M_FOUND, %V_FOUND, %P_FOUND) = "";
my ($Tname,$Tacc,$Ttype,$Tcoll,$Tcollnum,$Tst,$Tco,$Nacc,$Nurl,$Nproj,$phadd) = "";
my ($smasch_code, $smasch_name, $residue, $genus,$included, $errA, $err) = "";
my ($PRGuid,$PRacc, $Pacc, $Purl, $Pproj, $Fdat,$Facc,$Fguid,$Fproj,$Fdate,$Edat,$Eacc,$Eguid,$Eproj,$Edate) = "";
my (%BUFF_FOUND, %BUFF_SOU, %BUFF_LON, %BUFF_DAT, %BUFF_GBY, %BUFF_LAT, %BUFF_GN, %BUFF_GUNC) = "";
my ($bar,$idGEO,$latG,$longG,$GDatum,$GUNCInMeters,$GBy,$GSource,$GNote,$geodatum,$geosource,$geonote) = "";
my ($PHdat,$PHacc,$PHguid,$PHproj,$PHdate,$Vdat,$Vacc,$Vguid,$Vproj,$Vdate,$Mdat,$Macc,$Mguid,$Mproj,$Mdate) = "";
my ($Lmajor,$Lfam, %L_to_M,$Amajor,$Afam, %A_to_M,$Fmajor,$Ffam, %F_to_M,$Bmajor,$Bfam, %B_to_M) = "";
my ($LGmajor,$LGfam, %L_to_G,$AGmajor,$AGfam, %A_to_G,$FGmajor,$FGfam, %F_to_G,$BGmajor,$BGfam, %B_to_G,$AGgen,$BGgen,$LGgen,$FGgen) = "";

my ($uuid, $csid, $id, $name, $formatname, $family, $basionym, $major, $collectorsFormatted, $recordNumber) = "";
my ($verbatimEventDate, $EarlyCollectionDate, $LateCollectionDate, $locality, $tempCounty, $stateProvince, $country) = "";
my ($verbatimElevation, $minimumElevation, $maximumElevation, $elevation_units, $habitat, $verbatimLatitude) = "";
my ($verbatimLongitude, $verbatimCoordinates, $TRS, $datum, $georeferenceSources, $errorRadius, $coordinateUncertaintyUnits) = "";
my ($localityNote, $localitySource, $localitySourceDetail, $update, $labelHeader, $labelFooter, $previousDeterminations) = "";
my ($localName, $briefDescription, $depth, $minDepth, $maxDepth, $depthUnit, $associatedTaxa, $typeAssertions, $cultivated) = "";
my ($sex, $phase, $othernumber, $ucbgaccessionnumber, $determinationdetails, $loanstatus, $loannumber, $collectorverbatim) = "";
my ($otherlocalities, $alllocalities, $hastypeassertions, $determinationqualifier, $comments, $numberofobjects) = "";
my ($objectcount, $sheet, $create, $posttopublic, $references, $verbatimCollectors, $blob, $full_name, $temp_name, $otherCatNum) = "";

my ($coordinateUncertaintyinMeters, $georeferencedBy, $georeferenceRemarks, $longitude, $latitude) = "";
my ($elevationInFeet, $elevationInMeters, $county, $skipped, $bad_county, $status, $double) = "";
my ($georefremarks,$georeferencedby,$georefsource,$moe_add) = "";


my ($countGUNCMET, $countGNULL, $countGUNCPROB, $countGUNCMET, $countGUNCPROB, $countGNULL) = "";
my ($includedProblems, $Lexcl, $Aexcl, $Bexcl, $Fexcl, $photo_two) = "";
my ($includedF, $foundFskeletal, $foundFskeletalLOC, $foundFskeletalBADCLONE, $Fundiscovered_skeletal) = "";
my ($includedV, $foundVskeletal, $foundVskeletalLOC, $foundVskeletalBADCLONE, $Vundiscovered_skeletal,$foundVskeletalTYPE) = "";
my ($includedP, $foundPskeletal, $foundPskeletalLOC, $foundPskeletalBADCLONE, $Pundiscovered_skeletal) = "";
my ($includedM, $foundMskeletal, $foundMskeletalLOC, $foundMskeletalBADCLONE, $Mundiscovered_skeletal) = "";
my ($includedE, $foundEskeletal, $foundEskeletalLOC, $foundEskeletalBADCLONE, $Eundiscovered_skeletal) = "";
my ($includedEP, $foundEPskeletal, $foundEPskeletalLOC, $foundEPskeletalBADCLONE, $EPundiscovered_skeletal) = "";

my ($Mprocessed, $Mprob_processed, $Fprocessed, $Fprob_processed, $Eprocessed, $Eprob_processed) = "";
my ($Pprocessed, $Pprob_processed, $EPprocessed, $EPprob_processed, $Vprocessed, $Vprob_processed) = "";
my ($vasc_add, $alg_add, $lic_add, $bry_add) = "";
my ($alt_blob, $institutionCode, $ERUNC, $temp, %IMG_MED, $old_url,$count_record) = "";

my ($count, $photo, $countCULTNULL, $countCULT, $countTYPENULL, $countTYPE, $skipped_taxa, $otherData) = "";

my ($foundMskeletalTYPE, $foundFskeletalTYPE, $foundEskeletalTYPE, $foundEPskeletalTYPE, $foundPskeletalTYPE, $foundPskeletalTYPE) = ""; 

#note conversions
my ($countNote1, $countNote2, $countNote3, $countNoteNULL, $countCA, $countPROB, $countNULL) = "";

#georeference conversions
my ($countGLAT, $countGLON, $countGUNC, $countGSOU, $countGBY, $countGREM, $countGDAT) = "";
my ($countCAGeo,$countOTHER, $countCANOGeo, $countCAPROB, $countNONCAGeo, $countGeo, $countNON) = "";
my ($countUNCMET, $countUNCFT, $countUNCKM, $countUNCMIL, $countUNCNULL, $countUNCZERO, $countUNCFAIL1, $countUNCFAIL2) = "";

#elevation conversion
my ($countElevTemp, $countElevTemp1, $countElevTemp2, $countElevTemp3, $countElevTemp4, $countElevTemp5) = "";
my ($countElevTemp6, $countElevTemp7, $countElevTemp8, $countElevTemp9, $countElevTemp10, $countElevTemp11) = "";
my ($countElevTemp12, $countElevTemp13, $countElevTemp14, $countElevTemp15, $countElevTemp16, $countElevFail) = "";
my ($countElev, $countElev1, $countElev2, $countElev3, $countElev4, $countElev5, $countElev6, $countElev7) = "";
my ($countElev11, $countElev12, $countElev14, $countElev17, $countElev18, $countElev16, $countElev15, $countElev13) = "";
my ($countElevFail2, $countElev8, $countElev9, $countElev10, $countElevFail3,$ElevNOUNITS) = "";

#cultivated conversion
my ($countCULT1, $countCULT2, $countCULT3, $countCULT4, $countCULT5, $countCULT6, $countCULT7) = "";

#GUID conversion
my ($GUIDcount1,$GUIDcount2,$GUIDcount3,$GUIDcount4,$GUIDcount5)="";
my ($GUIDcount6,$GUIDcount7,$GUIDcount8,$GUIDcount9)="";
my ($PC)="";

#infile, bryophytes
my ($Bdat,$Bacc,$Bguid,$Bproj,$Bdate, %B_FOUND) = "";

#infile, lichens
my ($Ldat,$Lacc,$Lguid,$Lproj,$Ldate, %L_FOUND) = "";


#GUID outfile
my ($tempGUID,$UCID,$UCGUID,$countUUID,$changeUUID,%GUID_FOUND,$origUUID,$ug,$stat,$GUID,$guid_from_archive) = ""; 

#image files
my $IMG;
my $solr_csid;
my $solr_blob;
my ($blob1,$blob2,$blob3,$blob4,$blob5,$blob6,$blob7) = "";
my ($blobA,$blobB,$blobC,$blobD,$blobE,$blobF,$temp_blob,$COUNT) = "";
my ($solr_blob, $solr_group,$solr_csid,$blobNULL) = "";



############################ Begin field processing


my $solr_file="4solr.ucjeps.public.csv";


warn "=========\n\n\n";



##########

open(MER, ">UCJEPS_MERRITT_TITLE.txt") || die;



print MER "csid_s\taccessionnumber_s\tblob_ss\tMERRITT_TITLE\n";


#foreach ($accessions){

	open(IN,$solr_file) || die;
	Record: while(<IN>){
		chomp;
#
        if ($. == 1){	#activate if need to skip header lines
			next Record;
		}


		++$count;
		
		my @fields=split(/\t/, $_, 100);
		
		unless($#fields == 69){	#if the number of values in the columns array is exactly 70
		#unless($#fields == 66){	#if the number of values in the columns array is exactly 67

	##&CCH::log_skip ("$#fields bad field number $_\n");
	++$skipped;
	next Record;
	}	
		

#id	csid_s	accessionnumber_s	determination_s	termformatteddisplayname_s	family_s	taxonbasionym_s	majorgroup_s	collector_ss	collectornumber_s	
#id	csid_s	accessionnumber_s	determination_s	termformatteddisplayname_s	family_s	taxonbasionym_s	majorgroup_s	collector_ss	collectornumber_s	


#collectiondate_s	earlycollectiondate_dt	latecollectiondate_dt	locality_s	collcounty_s	collstate_s	collcountry_s	elevation_s	minelevation_s	maxelevation_s	elevationunit_s	
#collectiondate_s	earlycollectiondate_dt	latecollectiondate_dt	locality_s	collcounty_s	collstate_s	collcountry_s	elevation_s	minelevation_s	maxelevation_s	elevationunit_s	

#habitat_s	location_0_d	location_1_d	latlong_p	trscoordinates_s	datum_s	coordinatesource_s	coordinateuncertainty_f	coordinateuncertaintyunit_s	
#habitat_s	location_0_d	location_1_d	latlong_p	trscoordinates_s	datum_s	coordinatesource_s	coordinateuncertainty_f	coordinateuncertaintyunit_s	

#localitynote_s	localitysource_s	localitysourcedetail_s														updatedat_dt	labelheader_s	labelfooter_s	previousdeterminations_ss	localname_s	briefdescription_txt	
#localitynote_s	localitysource_s	localitysourcedetail_s	georefsource_s	georefremarks_s	georeferencedby_s	updatedat_dt	labelheader_s	labelfooter_s	previousdeterminations_ss	localname_s	briefdescription_s	

#depth_s	mindepth_s	maxdepth_s	depthunit_s	associatedtaxa_ss	typeassertions_ss	cultivated_s	sex_s	phase_s	othernumber_ss	ucbgaccessionnumber_s	
#depth_s	mindepth_s	maxdepth_s	depthunit_s	associatedtaxa_ss	typeassertions_ss	cultivated_s	sex_s	phase_s	othernumber_ss	ucbgaccessionnumber_s	


#determinationdetails_s	loanstatus_s	loannumber_s	collectorverbatim_s	otherlocalities_ss	alllocalities_ss	hastypeassertions_s	determinationqualifier_s	
#determinationdetails_s	loanstatus_s	loannumber_s	collectorverbatim_s	otherlocalities_ss	alllocalities_ss	hastypeassertions_s	determinationqualifier_s	

#comments_ss	numberofobjects_s	objectcount_s	sheet_s	createdat_dt	posttopublic_s	references_ss	collectors_verbatim_s	blob_ss
#comments_ss	numberofobjects_s	objectcount_s	sheet_s	createdat_dt	posttopublic_s	references_ss	collectors_verbatim_s	blob_ss



		($uuid, 
		$csid,
		$id,
		$temp_name,
		$formatname,
		$family,
		$basionym,
		$major,
		$collectorsFormatted,
		$recordNumber, #10
		$verbatimEventDate,
		$EarlyCollectionDate,
		$LateCollectionDate,
		$locality, 
		$tempCounty,
		$stateProvince,
		$country,
		$verbatimElevation,
		$minimumElevation,
		$maximumElevation, #20
		$elevation_units,
		$habitat,
		$verbatimLatitude,
		$verbatimLongitude, 
		$verbatimCoordinates,
		$TRS,
		$datum,  
		$georeferenceSources,
		$errorRadius,
		$coordinateUncertaintyUnits,#30
		$localityNote,
		$localitySource,
		$localitySourceDetail,
		$georefsource,
		$georefremarks,
		$georeferencedby,
		$update,
		$labelHeader,
		$labelFooter,
		$previousDeterminations,#40
		$localName,
		$briefDescription,
		$depth, 
		$minDepth,
		$maxDepth,
		$depthUnit,
		$associatedTaxa,
		$typeAssertions,
		$cultivated,
		$sex,#50
		$phase,
		$othernumber,
		$ucbgaccessionnumber, 
		$determinationdetails,
		$loanstatus,
		$loannumber,
		$collectorverbatim,
		$otherlocalities,
		$alllocalities,
		$hastypeassertions,#60
		$determinationqualifier,
		$comments,
		$numberofobjects, 
		$objectcount,
		$sheet,
		$create,
		$posttopublic,
		$references,
		$verbatimCollectors,
		$blob #70
		) = @fields;



#Project codes's are found in other number field under category Project Code,
#44b7fa63-5224-4431-bf4d-eb392a86f0cf (Symbiota GUID)


	if ($othernumber =~ m/^([a-z][a-z]?) +\(Project Code\)$/){
		$tempGUID = uc($1);
		$PC = "Project Code:".$tempGUID;
		++$GUIDcount1;
	}
	if ($othernumber =~ m/^([A-Z][A-Z]?) +\(Project Code\)$/){
		$tempGUID = $1;
		$PC = "Project Code:".$tempGUID;
		++$GUIDcount2;
	}
	elsif ($othernumber =~ m/^([a-z][a-z]?) +\(Project Code\)\|/){
		$tempGUID = uc($1);
		$PC = "Project Code:".$tempGUID;
		++$GUIDcount3;
	}
	elsif ($othernumber =~ m/^([A-Z][A-Z]?) +\(Project Code\)\|/){
		$tempGUID = $1;
		$PC = "Project Code:".$tempGUID;
		++$GUIDcount4;
	}
	elsif ($othernumber =~ m/\|([a-z][a-z]?) +\(Project Code\)\|/){
		$tempGUID = uc($1);
		$PC = "Project Code:".$tempGUID;
		++$GUIDcount5;
	}
	elsif ($othernumber =~ m/\|([A-Z][A-Z]?) +\(Project Code\)\|/){
		$tempGUID = $1;
		$PC = "Project Code:".$tempGUID;
		++$GUIDcount6;
	}
	elsif ($othernumber =~ m/\|([a-z][a-z]?) +\(Project Code\)$/){
		$tempGUID = uc($1);
		$PC = "Project Code:".$tempGUID;
		++$GUIDcount7;
	}
	elsif ($othernumber =~ m/\|([A-Z][A-Z]?) +\(Project Code\)$/){
		$tempGUID = $1;
		$PC = "Project Code:".$tempGUID;
		++$GUIDcount8;
	}
	else{
		$tempGUID = "";
		$PC = "";
		#$GUID = $csid;
		++$GUIDcount9; 
	}

my $TITLE = $id."/".$major."/".$formatname."/".$collectorsFormatted."/".$recordNumber."/".$PC;

####################RAW DATA export

print MER join("\t",
		$csid,
		$id,
		$blob,
		$TITLE
),"\n";



###############IMAGES#################

$solr_csid = $csid;
$solr_blob = $blob;


	if ($solr_blob =~ m/^ *$/){
		++$blobNULL;
	}
	elsif ($solr_blob =~ m/^([a-zA-Z0-9-]+)$/){
		$blobA = $1;

		++$blob1;

	#$IMG = "https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/".$blobA."/derivatives/OriginalJpeg/content";
	#$IMG_MED = "https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/".$blobA."/derivatives/Medium/content";
	}
	elsif ($solr_blob =~ m/^([a-zA-Z0-9-]+)\|([a-zA-Z0-9-]+)\|([a-zA-Z0-9-]+)\|([a-zA-Z0-9-]+)\|([a-zA-Z0-9-]+)\|([a-zA-Z0-9-]+)\|([a-zA-Z0-9-]+)$/){
		++$blob7;
		$blobA = $1;
		print "7 IMAGE BLOB==>".$solr_blob."\n";
	}
	elsif ($solr_blob =~ m/^([a-zA-Z0-9-]+)\|([a-zA-Z0-9-]+)\|([a-zA-Z0-9-]+)\|([a-zA-Z0-9-]+)\|([a-zA-Z0-9-]+)\|([a-zA-Z0-9-]+)$/){
		++$blob6;
		$blobA = $1;
		$blobB = $2;
		$blobC = $3;
		$blobD = $4;
		$blobE = $5;
		$blobF = $6;
		#as of May 2022, there is only one 6 image BLOB record, JEPS84903
		#it is all slide images of the plant in the field and no specimen image
		#skip this until a specimen image is made
		print "6 IMAGE BLOB==>".$solr_blob."\n";
	}
	elsif ($solr_blob =~ m/^([a-zA-Z0-9-]+)\|([a-zA-Z0-9-]+)\|([a-zA-Z0-9-]+)\|([a-zA-Z0-9-]+)\|([a-zA-Z0-9-]+)$/){
		$blobA = $1;
		$blobB = $2;
		$blobC = $3;
		$blobD = $4;
		$blobE = $5;

		++$blob5;
		print "5 IMAGE BLOB==>".$solr_blob."\n";
		
	#$IMG = "https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/".$blobA."/derivatives/OriginalJpeg/content | https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/".$blobB."/derivatives/OriginalJpeg/content | https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/".$blobC."/derivatives/OriginalJpeg/content | https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/".$blobD."/derivatives/OriginalJpeg/content | https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/".$blobE."/derivatives/OriginalJpeg/content";
	#$IMG_MED = "https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/".$blobA."/derivatives/Medium/content | https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/".$blobB."/derivatives/Medium/content | https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/".$blobC."/derivatives/Medium/content | https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/".$blobD."/derivatives/Medium/content | https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/".$blobE."/derivatives/Medium/content";
	}
	elsif ($solr_blob =~ m/^([a-zA-Z0-9-]+)\|([a-zA-Z0-9-]+)\|([a-zA-Z0-9-]+)\|([a-zA-Z0-9-]+)$/){
		$blobA = $1;
		$blobB = $2;
		$blobC = $3;
		$blobD = $4;

		++$blob4;

	#$IMG = "https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/".$blobA."/derivatives/OriginalJpeg/content | https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/".$blobB."/derivatives/OriginalJpeg/content | https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/".$blobC."/derivatives/OriginalJpeg/content | https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/".$blobD."/derivatives/OriginalJpeg/content";
	#$IMG_MED = "https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/".$blobA."/derivatives/Medium/content | https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/".$blobB."/derivatives/Medium/content | https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/".$blobC."/derivatives/Medium/content | https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/".$blobD."/derivatives/Medium/content";
	}
	elsif ($solr_blob =~ m/^([a-zA-Z0-9-]+)\|([a-zA-Z0-9-]+)\|([a-zA-Z0-9-]+)$/){
		$blobA = $1;
		$blobB = $2;
		$blobC = $3;

		++$blob3;

	#$IMG = "https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/".$blobA."/derivatives/OriginalJpeg/content | https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/".$blobB."/derivatives/OriginalJpeg/content | https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/".$blobC."/derivatives/OriginalJpeg/content";
	#$IMG_MED  = "https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/".$blobA."/derivatives/Medium/content | https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/".$blobB."/derivatives/Medium/content | https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/".$blobC."/derivatives/Medium/content";
	}
	elsif ($solr_blob =~ m/^([a-zA-Z0-9-]+)\|([a-zA-Z0-9-]+)$/){
		$blobA = $1;
		$blobB = $2;

		++$blob2;

	#$IMG = "https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/".$blobA."/derivatives/OriginalJpeg/content | https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/".$blobB."/derivatives/OriginalJpeg/content";
	#$IMG_MED = "https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/".$blobA."/derivatives/Medium/content | https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/".$blobB."/derivatives/Medium/content";
	}
	else {
		print "BAD BLOB-->$solr_blob==>$solr_csid\n\n";
	}
	
	#++$BLOB{$solr_csid};



}

print <<EOP;

TOTAL: $count

Project Code 1A (lower case problem fixed): $GUIDcount1
Project Code 1B OK: $GUIDcount2
Project Code 2A (lower case problem fixed): $GUIDcount3
Project Code 2B OK: $GUIDcount4
Project Code 3A (lower case problem fixed): $GUIDcount6
Project Code 3B OK: $GUIDcount6
Project Code 4A (lower case problem fixed): $GUIDcount7
Project Code 4B OK: $GUIDcount8

No Project Code: $GUIDcount9


CSpace records with 7 images: $blob7
CSpace records with 6 images: $blob6
CSpace records with 5 images: $blob5
CSpace records with 4 images: $blob4
CSpace records with 3 images: $blob3
CSpace records with 2 images: $blob2
CSpace records with 1 image: $blob1

No images: $blobNULL

EOP

close(IN);
close(MER);












