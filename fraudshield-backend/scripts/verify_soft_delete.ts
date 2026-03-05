import { prisma } from '../src/config/database';
import { ReportController } from '../src/controllers/report.controller';
import { AdminController } from '../src/controllers/admin.controller';

async function verifySoftDelete() {
    console.log('🚀 Starting Soft Delete Verification...');

    // 1. Find a test user
    const user = await prisma.user.findFirst();
    if (!user) {
        console.error('❌ No user found for testing');
        return;
    }

    const mockReq = {
        user: { id: user.id },
        body: {
            type: 'Phone',
            category: 'Scam Test',
            description: 'Soft delete verification report',
            target: '0123456789',
            isPublic: true,
            evidence: {}
        }
    } as any;

    const mockRes = {
        status: () => mockRes,
        json: (data: any) => { mockRes.data = data; return mockRes; },
        data: null as any
    } as any;

    // 2. Submit a report
    console.log('📝 Submitting test report...');
    await ReportController.submitReport(mockReq, mockRes, (err) => console.error(err));
    const reportId = mockRes.data.id;
    console.log(`✅ Report created: ${reportId}`);

    // 3. Verify it shows in public feed
    console.log('🔍 Checking public feed...');
    const feedReq = { query: {} } as any;
    await ReportController.getPublicFeed(feedReq, mockRes, (err) => console.error(err));
    let found = mockRes.data.results.some((r: any) => r.id === reportId);
    console.log(found ? '✅ Report visible in public feed' : '❌ Report NOT visible in public feed');

    // 4. Soft delete the report
    console.log('🗑️ Soft deleting report...');
    const deleteReq = { params: { id: reportId } } as any;
    await AdminController.deleteReport(deleteReq, mockRes, (err) => console.error(err));
    console.log(`✅ ${mockRes.data.message}`);

    // 5. Verify it is HIDDEN in public feed
    console.log('🔍 Re-checking public feed...');
    await ReportController.getPublicFeed(feedReq, mockRes, (err) => console.error(err));
    found = mockRes.data.results.some((r: any) => r.id === reportId);
    console.log(!found ? '✅ Report HIDDEN in public feed' : '❌ Report STILL visible in public feed');

    // 6. Verify it is HIDDEN in search
    console.log('🔍 Checking search...');
    const searchReq = { query: { q: 'Soft delete verification' } } as any;
    await ReportController.searchReports(searchReq, mockRes, (err) => console.error(err));
    found = mockRes.data.results.some((r: any) => r.id === reportId);
    console.log(!found ? '✅ Report HIDDEN in search results' : '❌ Report STILL visible in search results');

    // 7. Verify it still exists in DB
    console.log('🗄️ Checking database record...');
    const dbRecord = await prisma.scamReport.findUnique({ where: { id: reportId } });
    if (dbRecord && dbRecord.deletedAt) {
        console.log(`✅ DB record exists and has deletedAt: ${dbRecord.deletedAt}`);
    } else {
        console.log('❌ DB record missing or deletedAt not set');
    }

    console.log('\n🏁 Verification Finished.');
}

verifySoftDelete().catch(console.error);
