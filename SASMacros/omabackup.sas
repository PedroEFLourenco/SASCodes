options metaserver='<server>'
        metaport=8561
        metaprotocol=bridge
        metauser='<user>'
        metapass='<passwd>'
        metarepository='Foundation';
%OMABAKUP( DestinationPath="<SASHOME>\Lev1\SASBackup",
           ServerStartPath="<SASHOME>\Lev1\SASMain",
           RposmgrPath="MetadataServer\rposmgr",
           Reorg="Y", Restore="N", RunAnalysis="N",
           RepositoryList="Foundation")
