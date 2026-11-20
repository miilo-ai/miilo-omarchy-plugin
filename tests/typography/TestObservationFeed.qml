import QtQuick
import QtTest
import Quickshell
import "../../ui/components" as Miilo

Item {
    Miilo.ObservationFeed {id:feed;program:Quickshell.env("MIILO_CHAT_TEST_PEER");active:false}
    TestCase {
        name:"ObservationFeed"
        when:true
        onCompletedChanged:if(completed)console.log(qtest_results.failCount===0?"MIILO_FEED_OK":"MIILO_FEED_FAILED")
        function test_slow_refresh_keeps_previous_snapshot_and_completes() {
            feed.active=true;
            tryVerify(()=>!feed.stale&&feed.raw.length>0,2000);
            const previous=feed.raw;
            feed.expanded=true;
            wait(8500);
            compare(feed.stale,false);
            compare(feed.raw,previous);
            tryVerify(()=>feed.fetchedAt>Date.now()-1500,3000);
            compare(feed.snapshot.snapshot.providers.length,1);
            compare(feed.failures,0);
            feed.active=false;
        }
    }
}
