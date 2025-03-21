document.addEventListener('DOMContentLoaded', () => {
    const questionTextElement = document.getElementById('question-text');
    const answerInput = document.getElementById('answer-input');
    const submitButton = document.getElementById('submit-button');
    const feedbackContainer = document.getElementById('feedback-container');
    const feedbackTextElement = document.getElementById('feedback-text');
    const newQuestionButton = document.getElementById('new-question-button');
    const backendUrl = 'BACKEND_PLACEHOLDER';

    // Function to format and render feedback
    function renderFeedback(feedback) {
        feedbackTextElement.innerHTML = feedback
            .replace(/```(.*?)\n([\s\S]*?)```/g, '<pre><code>$2</code></pre>')
            .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')    // Bold
            .replace(/\*(.*?)\*/g, '<em>$1</em>')                // Italic
            .replace(/^- (.*?)(\n|$)/gm, '<li>$1</li>')           // Bullet points
            .replace(/\n/g, '<br>');                              // Line breaks
    }

    // Function to fetch a question from the backend
    const fetchQuestion = async () => {
        try {
            const response = await fetch(`${backendUrl}/api/question`);
            const data = await response.json();
            questionTextElement.textContent = data.question;
            answerInput.value = ''; // Clear answer input when new question is loaded
            feedbackContainer.classList.add('hidden'); // Hide feedback container
        } catch (error) {
            console.error('Error fetching question:', error);
            questionTextElement.textContent = 'Error loading question. Please check backend.';
        }
    };

    // Function to submit the answer to the backend
    const submitAnswer = async () => {
        const question = questionTextElement.textContent;
        const answer = answerInput.value;

        if (!answer.trim()) {
            alert('Please enter your answer.');
            return;
        }

        try {
            const response = await fetch(`${backendUrl}/api/submit`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ question: question, answer: answer }),
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.error || 'Submission failed');
            }

            const data = await response.json();
            renderFeedback(data.feedback); // Render formatted feedback
            feedbackContainer.classList.remove('hidden'); // Show feedback container
        } catch (error) {
            console.error('Error submitting answer:', error);
            alert(`Error submitting answer: ${error.message}`);
        }
    };

    // Event listener for submit button
    submitButton.addEventListener('click', submitAnswer);

    // Event listener for new question button
    newQuestionButton.addEventListener('click', fetchQuestion);

    // Fetch question on page load
    fetchQuestion();
});
