import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"

Chart.register(...registerables)

export default class extends Controller {
  connect() {
    const canvas = this.element.querySelector("#expenses-chart")
    if (!canvas) return

    const raw = this.element.dataset.chartData
    const data = raw ? JSON.parse(raw) : []

    if (data.length === 0) return

    const labels = data.map((d) => d.name)
    const values = data.map((d) => Number(d.total))
    const colors = [
      "#0d6efd",
      "#198754",
      "#6f42c1",
      "#fd7e14",
      "#dc3545",
      "#ffc107",
      "#20c997",
      "#0dcaf0",
      "#6c757d",
      "#e83e8c",
      "#198754",
      "#6f42c1",
    ]

    this.chart = new Chart(canvas, {
      type: "doughnut",
      data: {
        labels,
        datasets: [
          {
            data: values,
            backgroundColor: labels.map((_, i) => colors[i % colors.length]),
            borderWidth: 0,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        plugins: {
          legend: { display: false },
        },
      },
    })
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }
  }
}
