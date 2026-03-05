import { NlpMessageService } from './src/services/nlp-message.service';

const testCases = [
    "Transfer RM5000 to AC 12345 for PDRM investigation",
    "Sila pindahkan wang anda ke akaun selamat BNM untuk audit",
    "Waran tangkap telah dikeluarkan oleh mahkamah",
    "Normal grocery shopping for RM50",
];

testCases.forEach(test => {
    const result = NlpMessageService.analyze(test);
    console.log('--- TEST ---');
    console.log(`Input: ${test}`);
    console.log(`Score: ${result.score}`);
    console.log(`Type : ${result.scamType}`);
    console.log(`Patt : ${result.matchedPatterns.join(', ')}`);
});
