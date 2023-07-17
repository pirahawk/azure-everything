using Dapr.Actors;
using Dapr.Actors.Runtime;
using Microsoft.Extensions.Logging;

namespace AzContainerAppService.Dapr.Common
{
    public interface IOrderActor : IActor
    {
        Task<string> SaveStateAsync(OrderDataState orderData);
        Task<OrderDataState?> GetOrderStateAsync();
    }

    public class OrderActor : Actor, IOrderActor, IRemindable
    {
        const string ORDER_DATA_STATE = "ORDER_DATA_STATE";

        private readonly ILogger<OrderActor> logger;

        public OrderActor(ActorHost host, ILogger<OrderActor> logger) : base(host)
        {
            this.logger = logger;
        }

        protected override Task OnActivateAsync()
        {
            logger.LogInformation($"{nameof(OrderActor)} activated: {this.Id}");
            return base.OnActivateAsync();
        }

        public async Task<OrderDataState?> GetOrderStateAsync()
        {
            var hasState = await StateManager.ContainsStateAsync(ORDER_DATA_STATE);

            if (!hasState)
            {
                logger.LogWarning($"{nameof(OrderActor)} Id: {this.Id} Could not find actor state: {ORDER_DATA_STATE}");
                return null;
            }

            var state = await StateManager.GetStateAsync<OrderDataState>(ORDER_DATA_STATE);
            return state;
        }

        public async Task<string> SaveStateAsync(OrderDataState orderData)
        {
            await StateManager.SetStateAsync(ORDER_DATA_STATE, orderData);
            return orderData?.Name ?? string.Empty;
        }

        public Task ReceiveReminderAsync(string reminderName, byte[] state, TimeSpan dueTime, TimeSpan period)
        {
            throw new NotImplementedException();
        }
    }

    public record OrderDataState
    {
        public int Id { get; set; }
        public string? Name { get; set; }
        public int Quantity { get; set; }
        public bool Processed { get; set; }
    }
}